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
