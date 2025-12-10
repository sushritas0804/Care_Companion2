const Medication = require('../models/Medication');
const Recommendation = require('../models/Recommendation');

// Medical condition warnings
const conditionWarnings = {
  diabetes: 'Some medications may affect blood sugar levels.',
  heart_disease: 'NSAIDs may increase risk of heart attack or stroke.',
  high_bp: 'Some decongestants may raise blood pressure.',
  liver_disease: 'Avoid acetaminophen. Dose adjustment may be needed.',
  kidney_disease: 'Avoid NSAIDs. May worsen kidney function.',
  asthma: 'Some medications may trigger asthma attacks.',
  pregnant: 'Consult doctor before taking any medication.'
};

// Medication database mapping (in real app, this would be in database)
const symptomToCategoryMap = {
  headache: ['pain_fever'],
  fever: ['pain_fever'],
  cough: ['cough_cold'],
  sore_throat: ['cough_cold', 'pain_fever'],
  allergies: ['allergy_sinus'],
  indigestion: ['digestive_health'],
  diarrhea: ['digestive_health'],
  body_ache: ['pain_fever'],
  nasal_congestion: ['allergy_sinus', 'cough_cold'],
  heartburn: ['digestive_health'],
  nausea: ['digestive_health']
};

// Get recommendations based on symptoms
exports.getRecommendations = async (req, res, next) => {
  try {
    const {
      primarySymptom,
      secondarySymptoms = [],
      duration,
      medicalHistory = [],
      sessionId
    } = req.body;

    // Validate required fields
    if (!primarySymptom || !duration) {
      return res.status(400).json({
        status: 'error',
        message: 'Primary symptom and duration are required'
      });
    }

    // Generate session ID if not provided
    const finalSessionId = sessionId || `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // Get categories for symptoms
    const categories = symptomToCategoryMap[primarySymptom] || [];
    secondarySymptoms.forEach(symptom => {
      const symptomCategories = symptomToCategoryMap[symptom] || [];
      symptomCategories.forEach(cat => {
        if (!categories.includes(cat)) {
          categories.push(cat);
        }
      });
    });

    if (categories.length === 0) {
      return res.status(400).json({
        status: 'error',
        message: 'No medication categories found for the provided symptoms'
      });
    }

    // Find medications for the categories
    const medications = await Medication.find({
      category: { $in: categories },
      symptoms: { $in: [primarySymptom, ...secondarySymptoms] }
    }).lean();

    if (medications.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'No medications found for the provided symptoms'
      });
    }

    // Filter medications based on medical history
    const filteredMedications = [];
    const excludedMedications = [];

    medications.forEach(med => {
      let shouldInclude = true;
      let warnings = [];

      // Check medical history contraindications
      medicalHistory.forEach(condition => {
        // Check if medication has contraindications for this condition
        if (med.contraindications && med.contraindications.some(contra => 
          contra.toLowerCase().includes(condition.replace('_', ' '))
        )) {
          shouldInclude = false;
          excludedMedications.push({
            medication: med._id,
            reason: `Contraindicated for ${condition.replace('_', ' ')}`
          });
        }
        
        // Add warnings for certain conditions
        if (conditionWarnings[condition] && med.category === 'pain_fever') {
          warnings.push({
            condition: condition.replace('_', ' '),
            warning: conditionWarnings[condition]
          });
        }
      });

      if (shouldInclude) {
        // Generate dosage recommendation based on duration
        let dosageRecommendation = med.dosage.adult;
        if (duration === 'more than 1 week') {
          dosageRecommendation += ' (Consult doctor if symptoms persist beyond 7 days)';
        }

        filteredMedications.push({
          medication: med._id,
          reason: `Effective for ${primarySymptom.replace('_', ' ')}${secondarySymptoms.length > 0 ? ' and related symptoms' : ''}`,
          dosageRecommendation,
          warnings: warnings.length > 0 ? warnings.map(w => `${w.condition}: ${w.warning}`) : []
        });
      }
    });

    if (filteredMedications.length === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'All potential medications are contraindicated based on your medical history. Please consult a healthcare professional.'
      });
    }

    // Save recommendation to database (optional, based on user preference)
    let savedRecommendation = null;
    
    if (req.user) {
      savedRecommendation = await Recommendation.create({
        user: req.user.id,
        sessionId: finalSessionId,
        primarySymptom,
        secondarySymptoms,
        duration,
        medicalHistory,
        recommendedMedications: filteredMedications,
        excludedMedications,
        additionalRecommendations: duration === 'more than 1 week' 
          ? 'Symptoms have persisted for more than 1 week. Please consult a healthcare professional for proper diagnosis.'
          : null
      });
    } else {
      savedRecommendation = await Recommendation.create({
        sessionId: finalSessionId,
        primarySymptom,
        secondarySymptoms,
        duration,
        medicalHistory,
        recommendedMedications: filteredMedications,
        excludedMedications,
        additionalRecommendations: duration === 'more than 1 week' 
          ? 'Symptoms have persisted for more than 1 week. Please consult a healthcare professional for proper diagnosis.'
          : null
      });
    }

    // Populate medication details
    const populatedRecommendation = await Recommendation.findById(savedRecommendation._id)
      .populate('recommendedMedications.medication', 'name brandNames genericName category description dosage sideEffects warnings sources')
      .populate('excludedMedications.medication', 'name brandNames reason')
      .lean();

    res.status(200).json({
      status: 'success',
      message: 'Recommendations generated successfully',
      sessionId: finalSessionId,
      data: {
        recommendation: populatedRecommendation,
        summary: {
          primarySymptom,
          secondarySymptoms,
          duration,
          medicalHistory,
          totalMedicationsFound: medications.length,
          recommendedCount: filteredMedications.length,
          excludedCount: excludedMedications.length
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

// Get recommendation by session ID
exports.getRecommendationBySession = async (req, res, next) => {
  try {
    const { sessionId } = req.params;

    const recommendation = await Recommendation.findOne({ sessionId })
      .populate('recommendedMedications.medication')
      .populate('excludedMedications.medication')
      .lean();

    if (!recommendation) {
      return res.status(404).json({
        status: 'error',
        message: 'Recommendation not found'
      });
    }

    res.status(200).json({
      status: 'success',
      data: {
        recommendation
      }
    });
  } catch (error) {
    next(error);
  }
};

// Get user's recommendation history
exports.getUserRecommendations = async (req, res, next) => {
  try {
    const recommendations = await Recommendation.find({ user: req.user.id })
      .sort({ createdAt: -1 })
      .populate('recommendedMedications.medication', 'name category')
      .limit(20)
      .lean();

    res.status(200).json({
      status: 'success',
      results: recommendations.length,
      data: {
        recommendations
      }
    });
  } catch (error) {
    next(error);
  }
};
