const mongoose = require('mongoose');

const medicationSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Medication name is required'],
    trim: true,
    unique: true
  },
  brandNames: {
    type: [String],
    required: [true, 'Brand names are required']
  },
  genericName: {
    type: String,
    required: [true, 'Generic name is required']
  },
  category: {
    type: String,
    required: [true, 'Category is required'],
    enum: [
      'pain_fever',
      'allergy_sinus',
      'digestive_health',
      'cough_cold',
      'first_aid',
      'skin_care',
      'eye_care',
      'vitamins_supplements'
    ]
  },
  subCategory: {
    type: String,
    required: [true, 'Sub-category is required']
  },
  symptoms: {
    type: [String],
    required: [true, 'Symptoms are required']
  },
  description: {
    type: String,
    required: [true, 'Description is required']
  },
  dosage: {
    adult: {
      type: String,
      required: [true, 'Adult dosage is required']
    },
    children: {
      type: String,
      required: false
    },
    elderly: {
      type: String,
      required: false
    }
  },
  maxDailyDose: {
    type: String,
    required: [true, 'Maximum daily dose is required']
  },
  sideEffects: {
    type: [String],
    required: [true, 'Side effects are required']
  },
  warnings: {
    type: [String],
    required: [true, 'Warnings are required']
  },
  contraindications: {
    type: [String],
    default: []
  },
  interactions: {
    type: [String],
    default: []
  },
  pregnancyCategory: {
    type: String,
    enum: ['A', 'B', 'C', 'D', 'X', 'N'],
    required: true
  },
  storageInstructions: {
    type: String,
    required: [true, 'Storage instructions are required']
  },
  sources: [{
    name: String,
    url: String
  }],
  verified: {
    type: Boolean,
    default: false
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for faster queries
medicationSchema.index({ category: 1, subCategory: 1 });
medicationSchema.index({ symptoms: 1 });
medicationSchema.index({ name: 'text', genericName: 'text', brandNames: 'text' });

const Medication = mongoose.model('Medication', medicationSchema);

module.exports = Medication;
