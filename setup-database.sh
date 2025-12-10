#!/bin/bash
# setup-database.sh - Creates and configures MongoDB for Care Companion

echo "🗄️ Setting up MongoDB for Care Companion..."

# Check if we're in the right directory
if [ ! -d "care-companion" ]; then
    echo "❌ Project directory not found. Please run setup-frontend.sh first."
    exit 1
fi

cd care-companion

# Create database directory
mkdir -p database

echo "📊 Creating MongoDB configuration files..."

# Create init script for MongoDB
cat > database/init-mongo.js << 'EOF'
// MongoDB Initialization Script for Care Companion
// Run this with: mongosh mongodb://localhost:27017/carecompanion database/init-mongo.js

print("🚀 Initializing Care Companion Database...");

// Create database
db = db.getSiblingDB('carecompanion');

print("✅ Database 'carecompanion' created/selected");

// Create collections with validation
print("📁 Creating collections with schema validation...");

// Create medications collection
db.createCollection("medications", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["name", "category", "symptoms", "description", "dosage"],
      properties: {
        name: { bsonType: "string" },
        category: { bsonType: "string" },
        symptoms: { bsonType: "array" },
        description: { bsonType: "string" },
        dosage: { bsonType: "object" }
      }
    }
  }
});

// Create users collection
db.createCollection("users", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["email", "password", "fullName", "dateOfBirth"],
      properties: {
        email: { bsonType: "string", pattern: "^[^@]+@[^@]+\\.[^@]+$" },
        password: { bsonType: "string", minLength: 8 },
        fullName: { bsonType: "string", minLength: 2 }
      }
    }
  }
});

// Create recommendations collection
db.createCollection("recommendations", {
  timeseries: {
    timeField: "createdAt",
    metaField: "sessionId",
    granularity: "hours"
  },
  expireAfterSeconds: 2592000 // 30 days
});

print("✅ Collections created with schema validation");

// Create indexes for better performance
print("⚡ Creating indexes...");

// Medications indexes
db.medications.createIndex({ "category": 1 });
db.medications.createIndex({ "symptoms": 1 });
db.medications.createIndex({ "name": "text", "brandNames": "text", "genericName": "text" });

// Users indexes
db.users.createIndex({ "email": 1 }, { unique: true });

// Recommendations indexes
db.recommendations.createIndex({ "sessionId": 1 });
db.recommendations.createIndex({ "createdAt": -1 });

print("✅ Indexes created");

// Create database admin user (for production)
if (process.env.MONGO_INITDB_ROOT_USERNAME) {
  db.createUser({
    user: process.env.MONGO_INITDB_ROOT_USERNAME,
    pwd: process.env.MONGO_INITDB_ROOT_PASSWORD,
    roles: [
      { role: "dbOwner", db: "carecompanion" },
      { role: "readWrite", db: "carecompanion" }
    ]
  });
  print("🔐 Database admin user created");
}

// Insert sample data (optional)
print("📦 Inserting sample data...");

// Sample medications
const medications = [
  {
    name: "Ibuprofen",
    brandNames: ["Advil", "Motrin"],
    genericName: "Ibuprofen",
    category: "pain_fever",
    subCategory: "NSAIDs",
    symptoms: ["headache", "fever", "body_ache", "inflammation"],
    description: "Nonsteroidal anti-inflammatory drug for pain, fever, and inflammation.",
    dosage: {
      adult: "200-400mg every 4-6 hours as needed",
      children: "Consult pediatric dosage chart",
      elderly: "Use lowest effective dose"
    },
    maxDailyDose: "1200mg",
    sideEffects: ["Upset stomach", "Heartburn", "Dizziness", "Nausea"],
    warnings: [
      "Avoid if you have stomach ulcers",
      "Not recommended in last trimester of pregnancy",
      "May increase risk of heart attack or stroke"
    ],
    contraindications: ["Kidney disease", "Stomach ulcers", "Bleeding disorders"],
    interactions: ["Blood thinners", "Other NSAIDs", "ACE inhibitors"],
    pregnancyCategory: "C",
    storageInstructions: "Store at room temperature away from moisture and heat",
    sources: [
      { name: "Drugs.com", url: "https://www.drugs.com/ibuprofen.html" },
      { name: "MedlinePlus", url: "https://medlineplus.gov/druginfo/meds/a682159.html" }
    ],
    verified: true,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: "Acetaminophen",
    brandNames: ["Tylenol"],
    genericName: "Acetaminophen",
    category: "pain_fever",
    subCategory: "Analgesics",
    symptoms: ["headache", "fever", "body_ache"],
    description: "Pain reliever and fever reducer.",
    dosage: {
      adult: "325-650mg every 4-6 hours",
      children: "Consult pediatric dosage chart",
      elderly: "Use lowest effective dose"
    },
    maxDailyDose: "3000mg",
    sideEffects: ["Rare at recommended doses", "Liver damage at high doses"],
    warnings: [
      "Do not exceed daily limit",
      "Avoid with alcohol",
      "Check other medications for acetaminophen content"
    ],
    contraindications: ["Liver disease", "Alcoholism"],
    interactions: ["Warfarin", "Isoniazid"],
    pregnancyCategory: "B",
    storageInstructions: "Store at room temperature away from moisture and heat",
    sources: [
      { name: "Drugs.com", url: "https://www.drugs.com/acetaminophen.html" },
      { name: "Mayo Clinic", url: "https://www.mayoclinic.org/drugs-supplements/acetaminophen-oral-route/description/drg-20068480" }
    ],
    verified: true,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: "Loratadine",
    brandNames: ["Claritin"],
    genericName: "Loratadine",
    category: "allergy_sinus",
    subCategory: "Antihistamines",
    symptoms: ["allergies", "nasal_congestion", "runny_nose", "itchy_eyes"],
    description: "Non-drowsy allergy relief for sneezing, runny nose, itchy eyes.",
    dosage: {
      adult: "10mg once daily",
      children: "5mg once daily for ages 6+",
      elderly: "10mg once daily"
    },
    maxDailyDose: "10mg",
    sideEffects: ["Headache", "Dry mouth", "Fatigue"],
    warnings: [
      "May cause drowsiness in some people",
      "Take as directed",
      "Consult doctor for children under 6"
    ],
    contraindications: [],
    interactions: ["Some antibiotics", "Antifungals"],
    pregnancyCategory: "B",
    storageInstructions: "Store at room temperature away from light and moisture",
    sources: [
      { name: "Drugs.com", url: "https://www.drugs.com/loratadine.html" },
      { name: "MedlinePlus", url: "https://medlineplus.gov/druginfo/meds/a697038.html" }
    ],
    verified: true,
    createdAt: new Date(),
    updatedAt: new Date()
  }
];

// Insert medications
try {
  db.medications.insertMany(medications);
  print(`✅ Inserted ${medications.length} sample medications`);
} catch (e) {
  print("⚠️ Could not insert sample medications (might already exist)");
}

print("\n🎉 Database initialization complete!");
print("📊 Database: carecompanion");
print("📁 Collections: medications, users, recommendations");
print("🔗 Connection string: mongodb://localhost:27017/carecompanion");
EOF

# Create MongoDB Docker Compose file (optional)
cat > database/docker-compose.yml << 'EOF'
version: '3.8'

services:
  mongodb:
    image: mongo:6.0
    container_name: carecompanion-mongodb
    restart: unless-stopped
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: carecompanion123
      MONGO_INITDB_DATABASE: carecompanion
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
      - ./init-mongo.js:/docker-entrypoint-initdb.d/init-mongo.js:ro
    command: mongod --auth

  mongo-express:
    image: mongo-express:latest
    container_name: carecompanion-mongo-express
    restart: unless-stopped
    environment:
      ME_CONFIG_MONGODB_ADMINUSERNAME: admin
      ME_CONFIG_MONGODB_ADMINPASSWORD: carecompanion123
      ME_CONFIG_MONGODB_URL: mongodb://admin:carecompanion123@mongodb:27017/
      ME_CONFIG_BASICAUTH_USERNAME: admin
      ME_CONFIG_BASICAUTH_PASSWORD: admin123
    ports:
      - "8081:8081"
    depends_on:
      - mongodb

volumes:
  mongodb_data:
EOF

# Create MongoDB configuration for different environments
cat > database/mongodb-config.conf << 'EOF'
# MongoDB Configuration for Care Companion
# Save as: /etc/mongod.conf or use with --config option

storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 127.0.0.1

security:
  authorization: enabled

replication:
  replSetName: rs0

processManagement:
  fork: true
  pidFilePath: /var/run/mongodb/mongod.pid
EOF

# Create setup script for different OS
cat > database/setup-mongodb.sh << 'EOF'
#!/bin/bash
# MongoDB Setup Script for Care Companion - OS Specific

echo "🔧 MongoDB Setup for Care Companion"
echo "======================================"

# Detect operating system
OS=$(uname -s)

case $OS in
    "Linux")
        echo "🐧 Detected Linux"
        ./setup-linux.sh
        ;;
    "Darwin")
        echo "🍎 Detected macOS"
        ./setup-macos.sh
        ;;
    "MINGW"*|"CYGWIN"*|"MSYS"*)
        echo "🪟 Detected Windows (WSL/Git Bash)"
        ./setup-windows.sh
        ;;
    *)
        echo "❌ Unsupported operating system: $OS"
        exit 1
        ;;
esac
EOF

# Create Linux setup script
cat > database/setup-linux.sh << 'EOF'
#!/bin/bash
# MongoDB Setup for Linux (Ubuntu/Debian/CentOS)

echo "🚀 Installing MongoDB on Linux..."

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "❌ Cannot detect Linux distribution"
    exit 1
fi

case $DISTRO in
    "ubuntu"|"debian")
        echo "📦 Installing MongoDB on Ubuntu/Debian..."
        
        # Import MongoDB GPG Key
        wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
        
        # Create list file
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
        
        # Update packages
        sudo apt-get update
        
        # Install MongoDB
        sudo apt-get install -y mongodb-org
        
        # Start MongoDB service
        sudo systemctl start mongod
        sudo systemctl enable mongod
        sudo systemctl status mongod
        
        echo "✅ MongoDB installed and started"
        ;;
        
    "centos"|"rhel"|"fedora")
        echo "📦 Installing MongoDB on CentOS/RHEL/Fedora..."
        
        # Create repo file
        sudo tee /etc/yum.repos.d/mongodb-org-6.0.repo << 'REPO'
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
REPO
        
        # Install MongoDB
        sudo yum install -y mongodb-org
        
        # Start MongoDB service
        sudo systemctl start mongod
        sudo systemctl enable mongod
        
        echo "✅ MongoDB installed and started"
        ;;
        
    *)
        echo "❌ Unsupported Linux distribution: $DISTRO"
        echo "📚 Please install MongoDB manually from: https://docs.mongodb.com/manual/installation/"
        exit 1
        ;;
esac

# Initialize database
echo "📊 Initializing Care Companion database..."
mongosh --eval "db = db.getSiblingDB('carecompanion'); print('Database ready: carecompanion')"

echo "🎉 MongoDB setup complete on Linux!"
echo "🔗 Connection: mongodb://localhost:27017/carecompanion"
EOF

# Create macOS setup script
cat > database/setup-macos.sh << 'EOF'
#!/bin/bash
# MongoDB Setup for macOS

echo "🍎 Installing MongoDB on macOS..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Installing Homebrew first..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install MongoDB
echo "📦 Installing MongoDB via Homebrew..."
brew tap mongodb/brew
brew install mongodb-community@6.0

# Start MongoDB service
echo "🚀 Starting MongoDB service..."
brew services start mongodb-community@6.0

# Wait for MongoDB to start
sleep 5

# Check if MongoDB is running
if pgrep mongod > /dev/null; then
    echo "✅ MongoDB is running"
else
    echo "⚠️ MongoDB might not be running. Trying to start manually..."
    mongod --config /usr/local/etc/mongod.conf --fork
fi

# Initialize database
echo "📊 Initializing Care Companion database..."
mongosh --eval "db = db.getSiblingDB('carecompanion'); print('Database ready: carecompanion')"

echo "🎉 MongoDB setup complete on macOS!"
echo "🔗 Connection: mongodb://localhost:27017/carecompanion"
echo "📁 Data directory: /usr/local/var/mongodb"
EOF

# Create Windows setup script (for WSL)
cat > database/setup-windows.sh << 'EOF'
#!/bin/bash
# MongoDB Setup for Windows (WSL/Ubuntu)

echo "🪟 Setting up MongoDB on Windows (WSL)..."

# Check if running in WSL
if ! grep -q Microsoft /proc/version; then
    echo "⚠️ Not running in WSL. This script is for Windows Subsystem for Linux."
    echo "📚 For native Windows, install MongoDB from: https://www.mongodb.com/try/download/community"
    exit 1
fi

# Install MongoDB on WSL (Ubuntu)
echo "📦 Installing MongoDB on WSL Ubuntu..."

# Import MongoDB GPG Key
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -

# Create list file
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

# Update packages
sudo apt-get update

# Install MongoDB
sudo apt-get install -y mongodb-org

# Create data directory
sudo mkdir -p /data/db
sudo chown -R $USER /data/db

# Start MongoDB in the background
echo "🚀 Starting MongoDB..."
mongod --fork --logpath /tmp/mongodb.log

# Initialize database
echo "📊 Initializing Care Companion database..."
mongosh --eval "db = db.getSiblingDB('carecompanion'); print('Database ready: carecompanion')"

echo "🎉 MongoDB setup complete on Windows WSL!"
echo "🔗 Connection: mongodb://localhost:27017/carecompanion"
EOF

# Create quick start script
cat > database/quick-start.sh << 'EOF'
#!/bin/bash
# Quick Start MongoDB for Care Companion

echo "⚡ Quick Start MongoDB for Care Companion"
echo "============================================="

# Check if MongoDB is installed
if ! command -v mongosh &> /dev/null; then
    echo "❌ MongoDB not found. Installing..."
    chmod +x setup-mongodb.sh
    ./setup-mongodb.sh
fi

# Check if MongoDB is running
if pgrep mongod > /dev/null; then
    echo "✅ MongoDB is already running"
else
    echo "🚀 Starting MongoDB..."
    
    # Try different startup methods based on OS
    OS=$(uname -s)
    case $OS in
        "Linux")
            sudo systemctl start mongod 2>/dev/null || mongod --fork --logpath /tmp/mongodb.log
            ;;
        "Darwin")
            brew services start mongodb-community@6.0 2>/dev/null || mongod --fork --logpath /tmp/mongodb.log
            ;;
        *)
            mongod --fork --logpath /tmp/mongodb.log
            ;;
    esac
    
    sleep 3
fi

# Initialize database with our schema
echo "📊 Initializing Care Companion database..."
mongosh --quiet database/init-mongo.js

echo ""
echo "🎉 MongoDB is ready!"
echo "==================="
echo "📊 Database: carecompanion"
echo "🔗 Connection: mongodb://localhost:27017/carecompanion"
echo "📁 Collections: medications, users, recommendations"
echo ""
echo "💡 Next steps:"
echo "1. Start backend: cd ../backend && npm run dev"
echo "2. Start frontend: cd ../frontend && npm start"
echo "3. Open browser: http://localhost:3000"
EOF

# Create backup script
cat > database/backup-mongodb.sh << 'EOF'
#!/bin/bash
# MongoDB Backup Script for Care Companion

BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="carecompanion_backup_$DATE"

echo "💾 Creating MongoDB backup..."

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Create backup
mongodump --db carecompanion --out "$BACKUP_DIR/$BACKUP_NAME"

# Compress backup
tar -czf "$BACKUP_DIR/$BACKUP_NAME.tar.gz" -C "$BACKUP_DIR" "$BACKUP_NAME"

# Remove uncompressed backup
rm -rf "$BACKUP_DIR/$BACKUP_NAME"

echo "✅ Backup created: $BACKUP_DIR/$BACKUP_NAME.tar.gz"

# List recent backups
echo ""
echo "📁 Recent backups:"
ls -lh "$BACKUP_DIR"/*.tar.gz | tail -5
EOF

# Create restore script
cat > database/restore-mongodb.sh << 'EOF'
#!/bin/bash
# MongoDB Restore Script for Care Companion

BACKUP_DIR="./backups"

echo "🔄 Restoring MongoDB database..."

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ Backup directory not found: $BACKUP_DIR"
    exit 1
fi

# List available backups
echo "📁 Available backups:"
BACKUP_FILES=($(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null))

if [ ${#BACKUP_FILES[@]} -eq 0 ]; then
    echo "❌ No backup files found in $BACKUP_DIR"
    exit 1
fi

for i in "${!BACKUP_FILES[@]}"; do
    echo "  $((i+1)). ${BACKUP_FILES[$i]##*/}"
done

# Ask user to select backup
read -p "Select backup number to restore (1-${#BACKUP_FILES[@]}): " SELECTION

if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt "${#BACKUP_FILES[@]}" ]; then
    echo "❌ Invalid selection"
    exit 1
fi

SELECTED_BACKUP="${BACKUP_FILES[$((SELECTION-1))]}"

# Confirm restoration
read -p "Are you sure you want to restore from $SELECTED_BACKUP? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo "❌ Restoration cancelled"
    exit 0
fi

# Extract backup
TEMP_DIR=$(mktemp -d)
echo "📦 Extracting backup..."
tar -xzf "$SELECTED_BACKUP" -C "$TEMP_DIR"

# Restore database
echo "🔄 Restoring database..."
BACKUP_PATH=$(find "$TEMP_DIR" -name "carecompanion" -type d | head -1)

if [ -z "$BACKUP_PATH" ]; then
    echo "❌ Could not find backup data"
    rm -rf "$TEMP_DIR"
    exit 1
fi

mongorestore --drop "$BACKUP_PATH"

# Cleanup
rm -rf "$TEMP_DIR"

echo "✅ Database restored from: ${SELECTED_BACKUP##*/}"
EOF

# Create MongoDB connection test script
cat > database/test-connection.sh << 'EOF'
#!/bin/bash
# Test MongoDB Connection for Care Companion

echo "🔍 Testing MongoDB Connection..."
echo "================================"

# Test 1: Check if MongoDB is running
echo "1. Checking if MongoDB is running..."
if pgrep mongod > /dev/null; then
    echo "   ✅ MongoDB process is running"
else
    echo "   ❌ MongoDB is not running"
    echo "   💡 Start MongoDB with: ./quick-start.sh"
    exit 1
fi

# Test 2: Test connection
echo "2. Testing MongoDB connection..."
if mongosh --quiet --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
    echo "   ✅ MongoDB connection successful"
else
    echo "   ❌ Cannot connect to MongoDB"
    exit 1
fi

# Test 3: Check if database exists
echo "3. Checking Care Companion database..."
DB_EXISTS=$(mongosh --quiet --eval "db.getMongo().getDBs().databases.some(db => db.name === 'carecompanion')")

if [ "$DB_EXISTS" = "true" ]; then
    echo "   ✅ 'carecompanion' database exists"
    
    # Test 4: Check collections
    echo "4. Checking collections..."
    COLLECTIONS=$(mongosh carecompanion --quiet --eval "db.getCollectionNames().join(', ')")
    echo "   📁 Collections: $COLLECTIONS"
    
    # Test 5: Count documents
    echo "5. Counting documents..."
    MED_COUNT=$(mongosh carecompanion --quiet --eval "db.medications.countDocuments()")
    USER_COUNT=$(mongosh carecompanion --quiet --eval "db.users.countDocuments()")
    REC_COUNT=$(mongosh carecompanion --quiet --eval "db.recommendations.countDocuments()")
    
    echo "   📊 Medications: $MED_COUNT"
    echo "   👥 Users: $USER_COUNT"
    echo "   💡 Recommendations: $REC_COUNT"
else
    echo "   ❌ 'carecompanion' database not found"
    echo "   💡 Initialize database with: ./quick-start.sh"
fi

echo ""
echo "🎉 MongoDB Connection Test Complete!"
echo "🔗 Connection String: mongodb://localhost:27017/carecompanion"
EOF

# Make all scripts executable
chmod +x database/*.sh

# Create README for database setup
cat > database/README.md << 'EOF'
# MongoDB Setup for Care Companion

## Quick Start

Run the quick start script to set up MongoDB:
```bash
chmod +x quick-start.sh
./quick-start.sh