import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';

const Home = () => {
  const [activeCard, setActiveCard] = useState(1);

  useEffect(() => {
    // Parallax effect
    const handleScroll = () => {
      const pills = document.querySelectorAll('.parallax-pill');
      pills.forEach((pill, index) => {
        const speed = 0.2 + (index * 0.05);
        const yPos = -(window.scrollY * speed);
        pill.style.transform = `translateY(${yPos}px)`;
      });
    };

    window.addEventListener('scroll', handleScroll);
    
    // Mobile card rotation
    const interval = setInterval(() => {
      if (window.innerWidth <= 1024) {
        setActiveCard((prev) => (prev % 3) + 1);
      }
    }, 5000);

    return () => {
      window.removeEventListener('scroll', handleScroll);
      clearInterval(interval);
    };
  }, []);

  const handleCardClick = (cardNumber) => {
    setActiveCard(cardNumber);
  };

  const handleSearch = () => {
    const searchInput = document.querySelector('.search-input');
    if (searchInput.value.trim()) {
      alert(`Searching for "${searchInput.value}" across 4,500+ OTC medications...\n\nThis is a frontend demonstration.`);
    } else {
      searchInput.focus();
    }
  };

  return (
    <div className="content-overlay">
      {/* Enhanced 3D Parallax World */}
      <div className="parallax-world">
        <div className="parallax-layer layer-background"></div>
        <div className="parallax-pill pill-1"></div>
        <div className="parallax-pill pill-2"></div>
        <div className="parallax-pill pill-3"></div>
        <div className="parallax-pill pill-4"></div>
        <div className="parallax-pill pill-5"></div>
        <div className="parallax-pill pill-6"></div>
      </div>

      {/* Hero Section */}
      <section className="hero" id="home">
        <div className="hero-content">
          <div className="hero-grid">
            <div className="hero-text">
              <h1 className="hero-title">Find Trusted OTC Medication Information</h1>
              <p className="hero-subtitle">
                Access comprehensive, verified information from certified medical sources. 
                Search thousands of OTC medications with detailed usage instructions, side effects, and interactions.
              </p>
              
              <div className="search-container">
                <div className="search-box">
                  <input 
                    type="text" 
                    className="search-input" 
                    placeholder="Search for OTC medications"
                    onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
                  />
                  <button className="search-btn" onClick={handleSearch}>
                    <i className="fas fa-search"></i> Search
                  </button>
                </div>
              </div>
            </div>
            
            <div className="hero-visual">
              <div className="cards-container">
                <div className={`floating-card card-1 ${activeCard === 1 ? 'active-card' : ''}`}>
                  <img 
                    src="https://images.unsplash.com/photo-1559757148-5c350d0d3c56?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80" 
                    alt="Pain Relief Medications" 
                    className="card-image"
                  />
                  <div className="card-content">
                    <h3 className="card-title">Pain Relief</h3>
                    <p className="card-desc">Ibuprofen, Acetaminophen, Naproxen</p>
                    <Link to="/categories#painRelief">
                      <button className="btn btn-outline" style={{padding: '8px 20px', fontSize: '0.9rem'}}>
                        Explore
                      </button>
                    </Link>
                  </div>
                </div>
                
                <div className={`floating-card card-2 ${activeCard === 2 ? 'active-card' : ''}`}>
                  <img 
                    src="https://images.unsplash.com/photo-1587854692152-cbe660dbde88?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80" 
                    alt="Allergy Medications" 
                    className="card-image"
                  />
                  <div className="card-content">
                    <h3 className="card-title">Allergy Relief</h3>
                    <p className="card-desc">Loratadine, Cetirizine, Fexofenadine</p>
                    <Link to="/categories#allergyRelief">
                      <button className="btn btn-outline" style={{padding: '8px 20px', fontSize: '0.9rem'}}>
                        Explore
                      </button>
                    </Link>
                  </div>
                </div>
                
                <div className={`floating-card card-3 ${activeCard === 3 ? 'active-card' : ''}`}>
                  <img 
                    src="https://images.unsplash.com/photo-1551601651-2a8555f1a136?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80" 
                    alt="Digestive Health" 
                    className="card-image"
                  />
                  <div className="card-content">
                    <h3 className="card-title">Digestive Health</h3>
                    <p className="card-desc">Omeprazole, Famotidine, Loperamide</p>
                    <Link to="/categories#digestiveHealth">
                      <button className="btn btn-outline" style={{padding: '8px 20px', fontSize: '0.9rem'}}>
                        Explore
                      </button>
                    </Link>
                  </div>
                </div>
              </div>
              
              {/* Card Navigation Dots for Mobile */}
              <div className="card-navigation">
                <div 
                  className={`card-dot ${activeCard === 1 ? 'active' : ''}`} 
                  data-card="1"
                  onClick={() => handleCardClick(1)}
                ></div>
                <div 
                  className={`card-dot ${activeCard === 2 ? 'active' : ''}`} 
                  data-card="2"
                  onClick={() => handleCardClick(2)}
                ></div>
                <div 
                  className={`card-dot ${activeCard === 3 ? 'active' : ''}`} 
                  data-card="3"
                  onClick={() => handleCardClick(3)}
                ></div>
              </div>
            </div>
          </div>
          
          <div className="scroll-indicator">
            <i className="fas fa-chevron-down" style={{fontSize: '1.8rem'}}></i>
          </div>
        </div>
      </section>

      {/* OTC Categories Section */}
      <section className="section" id="categories">
        <h2 className="section-title">OTC Medication Categories</h2>
        <p className="section-subtitle">
          Browse medications by category to find the right OTC solution for your needs.
        </p>
        
        <div className="categories-container">
          <div className="category-card">
            <div className="category-icon">
              <i className="fas fa-head-side-virus"></i>
            </div>
            <h3 className="category-title">Pain & Fever Relief</h3>
            <p>Medications to reduce pain, fever, and inflammation.</p>
            <ul className="category-list">
              <li><strong>Ibuprofen</strong> - NSAID for pain and inflammation</li>
              <li><strong>Acetaminophen</strong> - Pain and fever reducer</li>
              <li><strong>Naproxen</strong> - Long-lasting pain relief</li>
              <li><strong>Aspirin</strong> - Pain relief and heart health</li>
            </ul>
            <Link to="/categories#painRelief">
              <button className="btn btn-outline">View All (24)</button>
            </Link>
          </div>
          
          <div className="category-card">
            <div className="category-icon">
              <i className="fas fa-wind"></i>
            </div>
            <h3 className="category-title">Allergy & Sinus</h3>
            <p>Relief from allergies, sinus pressure, and congestion.</p>
            <ul className="category-list">
              <li><strong>Loratadine</strong> - Non-drowsy allergy relief</li>
              <li><strong>Cetirizine</strong> - 24-hour allergy relief</li>
              <li><strong>Fexofenadine</strong> - Prescription-strength OTC</li>
              <li><strong>Pseudoephedrine</strong> - Nasal decongestant</li>
            </ul>
            <Link to="/categories#allergyRelief">
              <button className="btn btn-outline">View All (18)</button>
            </Link>
          </div>
          
          <div className="category-card">
            <div className="category-icon">
              <i className="fas fa-stomach"></i>
            </div>
            <h3 className="category-title">Digestive Health</h3>
            <p>For heartburn, indigestion, nausea, and diarrhea.</p>
            <ul className="category-list">
              <li><strong>Omeprazole</strong> - Acid reducer for heartburn</li>
              <li><strong>Famotidine</strong> - Fast-acting acid reducer</li>
              <li><strong>Loperamide</strong> - Anti-diarrheal</li>
              <li><strong>Simethicone</strong> - Gas relief</li>
            </ul>
            <Link to="/categories#digestiveHealth">
              <button className="btn btn-outline">View All (22)</button>
            </Link>
          </div>
        </div>
      </section>

      {/* Enhanced Parallax Info Section */}
      <section className="info-parallax" id="sources">
        <div className="parallax-content">
          <h2 className="parallax-title">Trusted Medical Sources</h2>
          <p style={{fontSize: '1.2rem', marginBottom: '2rem', lineHeight: '1.6', maxWidth: '800px', marginLeft: 'auto', marginRight: 'auto'}}>
            Care Companion aggregates information from the world's most trusted medical sources to provide you with accurate, up-to-date medication information.
          </p>
          
          <div className="stats-container">
            <div className="stat-item">
              <div className="stat-value">4,500+</div>
              <div className="stat-label">OTC Medications</div>
            </div>
            <div className="stat-item">
              <div className="stat-value">12</div>
              <div className="stat-label">Trusted Sources</div>
            </div>
            <div className="stat-item">
              <div className="stat-value">24/7</div>
              <div className="stat-label">Updated Information</div>
            </div>
            <div className="stat-item">
              <div className="stat-value">500K+</div>
              <div className="stat-label">Monthly Users</div>
            </div>
          </div>
        </div>
      </section>

      {/* OTC Medication Misuse Information */}
      <section className="section" id="misuse" style={{backgroundColor: 'var(--light-bg)'}}>
        <h2 className="section-title">Safe Use of OTC Medications</h2>
        <p className="section-subtitle">
          Important information about proper OTC medication use and common misuse risks.
        </p>
        
        <div className="misuse-container">
          <div className="misuse-card">
            <div className="misuse-icon">
              <i className="fas fa-exclamation-triangle"></i>
            </div>
            <h3 className="misuse-title">Common Misuse Risks</h3>
            <p>Over-the-counter medications are safe when used as directed, but misuse can lead to serious health problems.</p>
            <ul className="misuse-list">
              <li>Exceeding recommended dosages</li>
              <li>Using for longer than directed</li>
              <li>Taking multiple medications with same active ingredients</li>
              <li>Ignoring age restrictions</li>
              <li>Mixing with alcohol or other substances</li>
            </ul>
          </div>
          
          <div className="misuse-card warning-card">
            <div className="misuse-icon">
              <i className="fas fa-pills"></i>
            </div>
            <h3 className="misuse-title">Dosage Guidelines</h3>
            <p>Always follow label instructions carefully. Common dosage mistakes include:</p>
            <ul className="misuse-list">
              <li>Taking more frequent doses than recommended</li>
              <li>Doubling up on missed doses</li>
              <li>Using adult doses for children</li>
              <li>Not using proper measuring devices</li>
              <li>Continuing use beyond recommended duration</li>
            </ul>
          </div>
          
          <div className="misuse-card">
            <div className="misuse-icon">
              <i className="fas fa-user-md"></i>
            </div>
            <h3 className="misuse-title">When to Consult a Doctor</h3>
            <p>Seek medical attention if you experience any of the following:</p>
            <ul className="misuse-list">
              <li>Symptoms persist beyond recommended treatment duration</li>
              <li>Severe side effects or allergic reactions</li>
              <li>Uncertain about medication interactions</li>
              <li>Underlying health conditions (liver, kidney, heart)</li>
              <li>Pregnant, breastfeeding, or giving to young children</li>
            </ul>
          </div>
        </div>
      </section>
    </div>
  );
};

export default Home;
