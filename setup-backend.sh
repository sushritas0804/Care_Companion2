#!/bin/bash
# setup-backend.sh - Creates the complete Node.js/Express backend for Care Companion

echo "🚀 Setting up Care Companion Backend..."

# Check if frontend exists
if [ ! -d "care-companion/frontend" ]; then
    echo "❌ Frontend directory not found. Please run setup-frontend.sh first."
    exit 1
fi

# Navigate to project root
cd care-companion

# Create backend directory structure
echo "📁 Creating backend structure..."
mkdir -p backend/{models,routes,controllers,config,middleware,utils,data}

# Navigate to backend
cd backend

# Initialize Node.js project
echo "📦 Initializing Node.js project..."
npm init -y

# Install required dependencies
echo "📦 Installing dependencies..."
npm install express mongoose cors dotenv bcryptjs jsonwebtoken validator express-validator helmet morgan express-rate-limit nodemailer
npm install --save-dev nodemon

# Create server.js
echo "🔧 Creating server.js..."
cat > server.js << 'EOF'
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const path = require('path');
require('dotenv').config();

// Import routes
const authRoutes = require('./routes/auth');
const medicationRoutes = require('./routes/medications');
const recommendationRoutes = require('./routes/recommendations');

// Initialize express app
const app = express();

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

// Body parsing middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Logging middleware
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// Database connection
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/carecompanion', {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('✅ MongoDB connected successfully');
    
    // Seed initial data if needed
    await seedInitialData();
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
    process.exit(1);
  }
};

// Import seed function
const { seedMedications } = require('./utils/seedData');

// Seed initial data function
const seedInitialData = async () => {
  try {
    const Medication = require('./models/Medication');
    const count = await Medication.countDocuments();
    
    if (count === 0) {
      console.log('📦 Seeding initial medication data...');
      await seedMedications();
      console.log('✅ Medication data seeded successfully');
    }
  } catch (error) {
    console.error('❌ Error seeding data:', error);
  }
};

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/medications', medicationRoutes);
app.use('/api/recommendations', recommendationRoutes);

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'Care Companion API is running',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Serve frontend in production
if (process.env.NODE_ENV === 'production') {
  app.use(express.static(path.join(__dirname, '../frontend/build')));
  
  app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, '../frontend/build', 'index.html'));
  });
}

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('❌ Error:', err.stack);
  
  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal Server Error';
  
  res.status(statusCode).json({
    status: 'error',
    message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// Start server
const PORT = process.env.PORT || 5000;

const startServer = async () => {
  await connectDB();
  
  app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`🌐 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`📚 API Documentation available at: http://localhost:${PORT}/api/health`);
  });
};

startServer();

module.exports = app;
EOF

# Create models
echo "📊 Creating database models..."

# User model
cat > models/User.js << 'EOF'
const mongoose = require('mongoose');
const validator = require('validator');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  fullName: {
    type: String,
    required: [true, 'Full name is required'],
    trim: true,
    minlength: [2, 'Full name must be at least 2 characters'],
    maxlength: [100, 'Full name cannot exceed 100 characters']
  },
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    validate: [validator.isEmail, 'Please provide a valid email']
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: [8, 'Password must be at least 8 characters'],
    select: false
  },
  dateOfBirth: {
    type: Date,
    required: [true, 'Date of birth is required']
  },
  medicalHistory: {
    type: [String],
    enum: [
      'diabetes',
      'heart_disease',
      'high_bp',
      'liver_disease',
      'kidney_disease',
      'asthma',
      'pregnant',
      'none'
    ],
    default: []
  },
  allergies: {
    type: [String],
    default: []
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

// Virtual for age calculation
userSchema.virtual('age').get(function() {
  const today = new Date();
  const birthDate = new Date(this.dateOfBirth);
  let age = today.getFullYear() - birthDate.getFullYear();
  const monthDiff = today.getMonth() - birthDate.getMonth();
  
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
    age--;
  }
  
  return age;
});

// Password hashing middleware
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  try {
    const salt = await bcrypt.genSalt(12);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Password comparison method
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Update timestamp on save
userSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

const User = mongoose.model('User', userSchema);

module.exports = User;
EOF

# Medication model
cat > models/Medication.js << 'EOF'
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
EOF

# Recommendation model
cat > models/Recommendation.js << 'EOF'
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
EOF

# Create controllers
echo "🎮 Creating controllers..."

# Auth controller
cat > controllers/authController.js << 'EOF'
const User = require('../models/User');
const jwt = require('jsonwebtoken');
const validator = require('validator');

// Generate JWT token
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d'
  });
};

// Register new user
exports.register = async (req, res, next) => {
  try {
    const { fullName, email, password, dateOfBirth, medicalHistory } = req.body;

    // Validate input
    if (!fullName || !email || !password || !dateOfBirth) {
      return res.status(400).json({
        status: 'error',
        message: 'Please provide all required fields'
      });
    }

    if (!validator.isEmail(email)) {
      return res.status(400).json({
        status: 'error',
        message: 'Please provide a valid email address'
      });
    }

    if (password.length < 8) {
      return res.status(400).json({
        status: 'error',
        message: 'Password must be at least 8 characters long'
      });
    }

    // Check if user already exists
    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(409).json({
        status: 'error',
        message: 'User with this email already exists'
      });
    }

    // Calculate age from date of birth
    const dob = new Date(dateOfBirth);
    const today = new Date();
    let age = today.getFullYear() - dob.getFullYear();
    const monthDiff = today.getMonth() - dob.getMonth();
    
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < dob.getDate())) {
      age--;
    }

    if (age < 13) {
      return res.status(400).json({
        status: 'error',
        message: 'You must be at least 13 years old to register'
      });
    }

    // Create new user
    const user = await User.create({
      fullName,
      email: email.toLowerCase(),
      password,
      dateOfBirth: dob,
      medicalHistory: medicalHistory || []
    });

    // Remove password from response
    user.password = undefined;

    // Generate token
    const token = generateToken(user._id);

    res.status(201).json({
      status: 'success',
      message: 'User registered successfully',
      token,
      data: {
        user
      }
    });
  } catch (error) {
    next(error);
  }
};

// Login user
exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(400).json({
        status: 'error',
        message: 'Please provide email and password'
      });
    }

    // Find user and include password for comparison
    const user = await User.findOne({ email: email.toLowerCase() }).select('+password');
    
    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({
        status: 'error',
        message: 'Invalid email or password'
      });
    }

    // Remove password from response
    user.password = undefined;

    // Generate token
    const token = generateToken(user._id);

    res.status(200).json({
      status: 'success',
      message: 'Logged in successfully',
      token,
      data: {
        user
      }
    });
  } catch (error) {
    next(error);
  }
};

// Get current user profile
exports.getProfile = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);
    
    if (!user) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

    res.status(200).json({
      status: 'success',
      data: {
        user
      }
    });
  } catch (error) {
    next(error);
  }
};

// Update user profile
exports.updateProfile = async (req, res, next) => {
  try {
    const { fullName, medicalHistory, allergies } = req.body;
    
    const updateData = {};
    if (fullName) updateData.fullName = fullName;
    if (medicalHistory) updateData.medicalHistory = medicalHistory;
    if (allergies) updateData.allergies = allergies;

    const user = await User.findByIdAndUpdate(
      req.user.id,
      updateData,
      { new: true, runValidators: true }
    );

    if (!user) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

    res.status(200).json({
      status: 'success',
      message: 'Profile updated successfully',
      data: {
        user
      }
    });
  } catch (error) {
    next(error);
  }
};

// Logout (client-side token removal)
exports.logout = (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'Logged out successfully'
  });
};

// Forgot password (simplified version)
exports.forgotPassword = async (req, res, next) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        status: 'error',
        message: 'Please provide your email address'
      });
    }

    const user = await User.findOne({ email: email.toLowerCase() });
    
    if (!user) {
      // Don't reveal that user doesn't exist for security
      return res.status(200).json({
        status: 'success',
        message: 'If an account exists with this email, password reset instructions have been sent'
      });
    }

    // In a real application, you would:
    // 1. Generate a reset token
    // 2. Send email with reset link
    // 3. Store hashed reset token in database with expiry
    
    res.status(200).json({
      status: 'success',
      message: 'Password reset instructions have been sent to your email'
    });
  } catch (error) {
    next(error);
  }
};
EOF

# Medication controller
cat > controllers/medicationController.js << 'EOF'
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
EOF

# Recommendation controller
cat > controllers/recommendationController.js << 'EOF'
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
EOF

# Create middleware
echo "🛡️ Creating middleware..."

# Auth middleware
cat > middleware/auth.js << 'EOF'
const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Authentication middleware
exports.protect = async (req, res, next) => {
  try {
    let token;

    // Check if token exists in headers
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({
        status: 'error',
        message: 'You are not logged in. Please log in to access this resource.'
      });
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Check if user still exists
    const user = await User.findById(decoded.id);
    
    if (!user) {
      return res.status(401).json({
        status: 'error',
        message: 'The user belonging to this token no longer exists.'
      });
    }

    // Grant access to protected route
    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        status: 'error',
        message: 'Invalid token. Please log in again.'
      });
    }

    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        status: 'error',
        message: 'Your token has expired. Please log in again.'
      });
    }

    next(error);
  }
};

// Optional authentication middleware (doesn't require login but attaches user if token exists)
exports.optionalAuth = async (req, res, next) => {
  try {
    let token;

    // Check if token exists in headers
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (token) {
      // Verify token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // Check if user still exists
      const user = await User.findById(decoded.id);
      
      if (user) {
        req.user = user;
      }
    }

    next();
  } catch (error) {
    // If token is invalid, just continue without user
    next();
  }
};

// Role-based authorization (if needed in future)
exports.restrictTo = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        status: 'error',
        message: 'You do not have permission to perform this action.'
      });
    }
    next();
  };
};
EOF

# Create routes
echo "🛣️ Creating routes..."

# Auth routes
cat > routes/auth.js << 'EOF'
const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const auth = require('../middleware/auth');

// Public routes
router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/forgot-password', authController.forgotPassword);
router.get('/logout', authController.logout);

// Protected routes
router.get('/profile', auth.protect, authController.getProfile);
router.put('/profile', auth.protect, authController.updateProfile);

module.exports = router;
EOF

# Medication routes
cat > routes/medications.js << 'EOF'
const express = require('express');
const router = express.Router();
const medicationController = require('../controllers/medicationController');
const auth = require('../middleware/auth');

// Public routes
router.get('/', medicationController.getAllMedications);
router.get('/search', medicationController.searchMedications);
router.get('/categories', medicationController.getCategories);
router.get('/categories/:category', medicationController.getMedicationsByCategory);
router.get('/popular', medicationController.getPopularMedications);
router.get('/:id', medicationController.getMedicationById);

// Protected routes (for future admin features)
// router.post('/', auth.protect, auth.restrictTo('admin'), medicationController.createMedication);
// router.put('/:id', auth.protect, auth.restrictTo('admin'), medicationController.updateMedication);
// router.delete('/:id', auth.protect, auth.restrictTo('admin'), medicationController.deleteMedication);

module.exports = router;
EOF

# Recommendation routes
cat > routes/recommendations.js << 'EOF'
const express = require('express');
const router = express.Router();
const recommendationController = require('../controllers/recommendationController');
const auth = require('../middleware/auth');
const optionalAuth = require('../middleware/auth').optionalAuth;

// Get recommendations (with optional authentication)
router.post('/', optionalAuth, recommendationController.getRecommendations);

// Get recommendation by session ID
router.get('/session/:sessionId', recommendationController.getRecommendationBySession);

// Protected routes (user history)
router.get('/history', auth.protect, recommendationController.getUserRecommendations);

module.exports = router;
EOF

# Create utils/seedData.js
echo "🌱 Creating seed data utility..."
cat > utils/seedData.js << 'EOF'
const Medication = require('../models/Medication');

// Sample medication data
const medicationData = [
  {
    name: 'Ibuprofen',
    brandNames: ['Advil', 'Motrin'],
    genericName: 'Ibuprofen',
    category: 'pain_fever',
    subCategory: 'NSAIDs',
    symptoms: ['headache', 'fever', 'body_ache', 'inflammation'],
    description: 'Nonsteroidal anti-inflammatory drug for pain, fever, and inflammation.',
    dosage: {
      adult: '200-400mg every 4-6 hours as needed',
      children: 'Consult pediatric dosage chart',
      elderly: 'Use lowest effective dose'
    },
    maxDailyDose: '1200mg',
    sideEffects: ['Upset stomach', 'Heartburn', 'Dizziness', 'Nausea'],
    warnings: [
      'Avoid if you have stomach ulcers',
      'Not recommended in last trimester of pregnancy',
      'May increase risk of heart attack or stroke',
      'Take with food to reduce stomach upset'
    ],
    contraindications: ['Kidney disease', 'Stomach ulcers', 'Bleeding disorders'],
    interactions: ['Blood thinners', 'Other NSAIDs', 'ACE inhibitors'],
    pregnancyCategory: 'C',
    storageInstructions: 'Store at room temperature away from moisture and heat',
    sources: [
      { name: 'Drugs.com', url: 'https://www.drugs.com/ibuprofen.html' },
      { name: 'MedlinePlus', url: 'https://medlineplus.gov/druginfo/meds/a682159.html' }
    ],
    verified: true
  },
  {
    name: 'Acetaminophen',
    brandNames: ['Tylenol'],
    genericName: 'Acetaminophen',
    category: 'pain_fever',
    subCategory: 'Analgesics',
    symptoms: ['headache', 'fever', 'body_ache'],
    description: 'Pain reliever and fever reducer.',
    dosage: {
      adult: '325-650mg every 4-6 hours',
      children: 'Consult pediatric dosage chart',
      elderly: 'Use lowest effective dose'
    },
    maxDailyDose: '3000mg',
    sideEffects: ['Rare at recommended doses', 'Liver damage at high doses'],
    warnings: [
      'Do not exceed daily limit',
      'Avoid with alcohol',
      'Check other medications for acetaminophen content',
      'May cause liver damage in overdose'
    ],
    contraindications: ['Liver disease', 'Alcoholism'],
    interactions: ['Warfarin', 'Isoniazid'],
    pregnancyCategory: 'B',
    storageInstructions: 'Store at room temperature away from moisture and heat',
    sources: [
      { name: 'Drugs.com', url: 'https://www.drugs.com/acetaminophen.html' },
      { name: 'Mayo Clinic', url: 'https://www.mayoclinic.org/drugs-supplements/acetaminophen-oral-route/description/drg-20068480' }
    ],
    verified: true
  },
  {
    name: 'Loratadine',
    brandNames: ['Claritin'],
    genericName: 'Loratadine',
    category: 'allergy_sinus',
    subCategory: 'Antihistamines',
    symptoms: ['allergies', 'nasal_congestion', 'runny_nose', 'itchy_eyes'],
    description: 'Non-drowsy allergy relief for sneezing, runny nose, itchy eyes.',
    dosage: {
      adult: '10mg once daily',
      children: '5mg once daily for ages 6+',
      elderly: '10mg once daily'
    },
    maxDailyDose: '10mg',
    sideEffects: ['Headache', 'Dry mouth', 'Fatigue'],
    warnings: [
      'May cause drowsiness in some people',
      'Take as directed',
      'Consult doctor for children under 6'
    ],
    contraindications: [],
    interactions: ['Some antibiotics', 'Antifungals'],
    pregnancyCategory: 'B',
    storageInstructions: 'Store at room temperature away from light and moisture',
    sources: [
      { name: 'Drugs.com', url: 'https://www.drugs.com/loratadine.html' },
      { name: 'MedlinePlus', url: 'https://medlineplus.gov/druginfo/meds/a697038.html' }
    ],
    verified: true
  },
  {
    name: 'Omeprazole',
    brandNames: ['Prilosec'],
    genericName: 'Omeprazole',
    category: 'digestive_health',
    subCategory: 'Proton Pump Inhibitors',
    symptoms: ['heartburn', 'indigestion', 'acid_reflux'],
    description: 'Acid reducer for heartburn and acid reflux.',
    dosage: {
      adult: '20mg once daily before eating',
      children: 'Consult doctor',
      elderly: '20mg once daily'
    },
    maxDailyDose: '40mg',
    sideEffects: ['Headache', 'Diarrhea', 'Nausea', 'Abdominal pain'],
    warnings: [
      'Do not use for more than 14 days continuously',
      'May increase risk of bone fractures with long-term use',
      'Consult doctor for persistent symptoms'
    ],
    contraindications: [],
    interactions: ['Clopidogrel', 'Ketoconazole'],
    pregnancyCategory: 'C',
    storageInstructions: 'Store at room temperature away from moisture',
    sources: [
      { name: 'Drugs.com', url: 'https://www.drugs.com/omeprazole.html' },
      { name: 'FDA', url: 'https://www.fda.gov/drugs/postmarket-drug-safety-information-patients-and-providers/omeprazole-magnesium' }
    ],
    verified: true
  },
  {
    name: 'Dextromethorphan',
    brandNames: ['Robitussin', 'Delsym'],
    genericName: 'Dextromethorphan',
    category: 'cough_cold',
    subCategory: 'Cough Suppressants',
    symptoms: ['cough'],
    description: 'Suppresses the urge to cough.',
    dosage: {
      adult: '10-20mg every 4 hours or 30mg every 6-8 hours',
      children: 'Consult pediatric dosage chart',
      elderly: 'Use lowest effective dose'
    },
    maxDailyDose: '120mg',
    sideEffects: ['Drowsiness', 'Dizziness', 'Nausea'],
    warnings: [
      'Do not use with MAO inhibitors',
      'May cause drowsiness',
      'Not for chronic cough from smoking or asthma'
    ],
    contraindications: ['MAO inhibitor use'],
    interactions: ['MAO inhibitors', 'Antidepressants'],
    pregnancyCategory: 'C',
    storageInstructions: 'Store at room temperature',
    sources: [
      { name: 'Drugs.com', url: 'https://www.drugs.com/dextromethorphan.html' },
      { name: 'MedlinePlus', url: 'https://medlineplus.gov/druginfo/meds/a682492.html' }
    ],
    verified: true
  }
];

// Seed function
const seedMedications = async () => {
  try {
    // Clear existing data
    await Medication.deleteMany({});
    
    // Insert new data
    await Medication.insertMany(medicationData);
    
    console.log(`✅ Seeded ${medicationData.length} medications`);
  } catch (error) {
    console.error('❌ Error seeding medications:', error);
  }
};

module.exports = { seedMedications, medicationData };
EOF

# Create config/database.js
cat > config/database.js << 'EOF'
const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/carecompanion', {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });

    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
    return conn;
  } catch (error) {
    console.error(`❌ MongoDB Connection Error: ${error.message}`);
    process.exit(1);
  }
};

module.exports = connectDB;
EOF

# Create .env file
cat > .env << 'EOF'
# Server Configuration
PORT=5000
NODE_ENV=development
FRONTEND_URL=http://localhost:3000

# Database Configuration
MONGODB_URI=mongodb://localhost:27017/carecompanion

# JWT Configuration
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production
JWT_EXPIRES_IN=7d

# API Configuration
API_VERSION=v1
API_RATE_LIMIT_WINDOW_MS=900000
API_RATE_LIMIT_MAX_REQUESTS=100

# Email Configuration (for future use)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_email_password
EMAIL_FROM=noreply@carecompanion.com

# Security Configuration
CORS_ORIGIN=http://localhost:3000
HELMET_ENABLED=true
MORGAN_FORMAT=dev
EOF

# Create .env.example
cat > .env.example << 'EOF'
# Server Configuration
PORT=5000
NODE_ENV=development
FRONTEND_URL=http://localhost:3000

# Database Configuration
MONGODB_URI=mongodb://localhost:27017/carecompanion

# JWT Configuration
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production
JWT_EXPIRES_IN=7d

# API Configuration
API_VERSION=v1

# Email Configuration (for future use)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_email_password
EMAIL_FROM=noreply@carecompanion.com
EOF

# Update package.json with scripts
cat > package.json << 'EOF'
{
  "name": "care-companion-backend",
  "version": "1.0.0",
  "description": "Backend API for Care Companion - OTC Medication Information Platform",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "seed": "node -e \"require('./utils/seedData').seedMedications()\"",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [
    "medication",
    "healthcare",
    "otc",
    "api",
    "nodejs",
    "express",
    "mongodb"
  ],
  "author": "Care Companion Team",
  "license": "MIT",
  "dependencies": {
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.0.3",
    "express": "^4.18.2",
    "express-rate-limit": "^6.7.0",
    "helmet": "^7.0.0",
    "jsonwebtoken": "^9.0.0",
    "mongoose": "^7.0.3",
    "morgan": "^1.10.0",
    "nodemailer": "^6.9.1",
    "validator": "^13.9.0"
  },
  "devDependencies": {
    "nodemon": "^2.0.22"
  }
}
EOF

# Create README for backend
cat > README.md << 'EOF'
# Care Companion Backend API

## Overview
This is the backend API for the Care Companion platform, providing OTC medication information and recommendations.

## Features
- User authentication and authorization
- Medication database with detailed information
- Intelligent medication recommendations based on symptoms
- Medical history consideration
- RESTful API design

## Tech Stack
- Node.js & Express
- MongoDB & Mongoose
- JWT for authentication
- Rate limiting and security middleware

## Getting Started

### Prerequisites
- Node.js 16+
- MongoDB 4.4+
- npm or yarn

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   npm install