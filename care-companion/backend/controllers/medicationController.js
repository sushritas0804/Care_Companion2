const Medication = require('../models/Medication');

// Get all medications with filters
exports.getAllMedications = async (req, res, next) => {
  try {
    const {
      category,
      subCategory,
      symptom,
      search,
      page = 1,
      limit = 20
    } = req.query;

    // Build query
    const query = {};
    
    if (category) query.category = category;
    if (subCategory) query.subCategory = subCategory;
    if (symptom) query.symptoms = { $in: [symptom] };

    // Text search
    if (search) {
      query.$text = { $search: search };
    }

    // Pagination
    const skip = (page - 1) * limit;

    // Execute query
    const medications = await Medication.find(query)
      .sort({ name: 1 })
      .skip(skip)
      .limit(parseInt(limit))
      .lean();

    const total = await Medication.countDocuments(query);

    res.status(200).json({
      status: 'success',
      results: medications.length,
      total,
      page: parseInt(page),
      totalPages: Math.ceil(total / limit),
      data: {
        medications
      }
    });
  } catch (error) {
    next(error);
  }
};

// Get single medication by ID
exports.getMedicationById = async (req, res, next) => {
  try {
    const medication = await Medication.findById(req.params.id).lean();

    if (!medication) {
      return res.status(404).json({
        status: 'error',
        message: 'Medication not found'
      });
    }

    res.status(200).json({
      status: 'success',
      data: {
        medication
      }
    });
  } catch (error) {
    next(error);
  }
};

// Search medications
exports.searchMedications = async (req, res, next) => {
  try {
    const { q, category, limit = 10 } = req.query;

    if (!q) {
      return res.status(400).json({
        status: 'error',
        message: 'Search query is required'
      });
    }

    const query = {
      $text: { $search: q }
    };

    if (category) {
      query.category = category;
    }

    const medications = await Medication.find(query)
      .select('name brandNames genericName category symptoms description')
      .limit(parseInt(limit))
      .lean();

    res.status(200).json({
      status: 'success',
      results: medications.length,
      data: {
        medications
      }
    });
  } catch (error) {
    next(error);
  }
};

// Get medications by category
exports.getMedicationsByCategory = async (req, res, next) => {
  try {
    const { category } = req.params;
    const { subCategory } = req.query;

    const query = { category };
    
    if (subCategory) {
      query.subCategory = subCategory;
    }

    const medications = await Medication.find(query)
      .select('name brandNames genericName symptoms description dosage.adult')
      .sort({ name: 1 })
      .lean();

    // Group by subCategory if no specific subCategory requested
    let groupedMedications = {};
    if (!subCategory) {
      medications.forEach(med => {
        if (!groupedMedications[med.subCategory]) {
          groupedMedications[med.subCategory] = [];
        }
        groupedMedications[med.subCategory].push(med);
      });
    }

    res.status(200).json({
      status: 'success',
      results: medications.length,
      data: {
        category,
        subCategory,
        medications: subCategory ? medications : groupedMedications,
        grouped: !subCategory
      }
    });
  } catch (error) {
    next(error);
  }
};

// Get medication categories
exports.getCategories = async (req, res, next) => {
  try {
    const categories = await Medication.aggregate([
      {
        $group: {
          _id: '$category',
          count: { $sum: 1 },
          subCategories: { $addToSet: '$subCategory' }
        }
      },
      {
        $project: {
          category: '$_id',
          count: 1,
          subCategories: 1,
          _id: 0
        }
      },
      { $sort: { category: 1 } }
    ]);

    // Map to user-friendly names
    const categoryMap = {
      'pain_fever': 'Pain & Fever Relief',
      'allergy_sinus': 'Allergy & Sinus',
      'digestive_health': 'Digestive Health',
      'cough_cold': 'Cough & Cold',
      'first_aid': 'First Aid',
      'skin_care': 'Skin Care',
      'eye_care': 'Eye Care',
      'vitamins_supplements': 'Vitamins & Supplements'
    };

    const formattedCategories = categories.map(cat => ({
      ...cat,
      displayName: categoryMap[cat.category] || cat.category,
      subCategories: cat.subCategories.sort()
    }));

    res.status(200).json({
      status: 'success',
      results: categories.length,
      data: {
        categories: formattedCategories
      }
    });
  } catch (error) {
    next(error);
  }
};

// Get popular medications (based on symptoms)
exports.getPopularMedications = async (req, res, next) => {
  try {
    const commonSymptoms = [
      'headache',
      'fever',
      'cough',
      'sore_throat',
      'allergies',
      'heartburn',
      'diarrhea'
    ];

    const medications = await Medication.find({
      symptoms: { $in: commonSymptoms }
    })
    .select('name brandNames category symptoms description')
    .limit(12)
    .lean();

    res.status(200).json({
      status: 'success',
      results: medications.length,
      data: {
        medications
      }
    });
  } catch (error) {
    next(error);
  }
};
