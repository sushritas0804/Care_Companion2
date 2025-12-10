const mongoose = require('mongoose');

const recommendationSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: false // Can be anonymous
  },
  sessionId: {
    type: String,
    required: [true, 'Session ID is required']
  },
  primarySymptom: {
    type: String,
    required: [true, 'Primary symptom is required'],
    enum: [
      'headache',
      'fever',
      'cough',
      'sore_throat',
      'allergies',
      'indigestion',
      'diarrhea',
      'body_ache',
      'nasal_congestion',
      'heartburn',
      'nausea'
    ]
  },
  secondarySymptoms: {
    type: [String],
    default: []
  },
  duration: {
    type: String,
    required: [true, 'Duration is required'],
    enum: ['1-3 days', '3-7 days', 'more than 1 week']
  },
  medicalHistory: {
    type: [String],
    default: []
  },
  recommendedMedications: [{
    medication: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Medication',
      required: true
    },
    reason: String,
    dosageRecommendation: String,
    warnings: [String]
  }],
  excludedMedications: [{
    medication: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Medication'
    },
    reason: String
  }],
  additionalRecommendations: {
    type: String
  },
  createdAt: {
    type: Date,
    default: Date.now,
    expires: 30 * 24 * 60 * 60 // Auto-delete after 30 days
  }
});

// Index for session-based retrieval
recommendationSchema.index({ sessionId: 1 });
recommendationSchema.index({ user: 1, createdAt: -1 });

const Recommendation = mongoose.model('Recommendation', recommendationSchema);

module.exports = Recommendation;
