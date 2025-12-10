import React from 'react';
import { Link } from 'react-router-dom';

const Footer = () => {
  return (
    <footer className="footer" id="about">
      <div className="footer-content">
        <div className="footer-section">
          <h3>Care Companion</h3>
          <p>Your trusted source for OTC medication information. We aggregate data from certified medical sources to provide comprehensive, accurate information.</p>
          <div style={{marginTop: '1.5rem'}}>
            <Link to="/auth#signup">
              <button className="btn btn-primary">Get Started</button>
            </Link>
          </div>
        </div>
        
        <div className="footer-section">
          <h3>Quick Links</h3>
          <ul className="footer-links">
            <li><Link to="/">Home</Link></li>
            <li><a href="#categories">Medication Categories</a></li>
            <li><a href="#misuse">Safe Use Guidelines</a></li>
            <li><a href="#sources">Trusted Sources</a></li>
          </ul>
        </div>
        
        <div className="footer-section">
          <h3>Sources</h3>
          <ul className="footer-links">
            <li><a href="https://www.drugs.com" target="_blank" rel="noopener noreferrer">Drugs.com</a></li>
            <li><a href="https://medlineplus.gov" target="_blank" rel="noopener noreferrer">MedlinePlus</a></li>
            <li><a href="https://www.mayoclinic.org" target="_blank" rel="noopener noreferrer">Mayo Clinic</a></li>
            <li><a href="https://www.fda.gov" target="_blank" rel="noopener noreferrer">FDA</a></li>
          </ul>
        </div>
        
        <div className="footer-section">
          <h3>Contact</h3>
          <ul className="footer-links">
            <li><a href="mailto:info@carecompanion.com">info@carecompanion.com</a></li>
            <li><a href="#">Privacy Policy</a></li>
            <li><a href="#">Terms of Use</a></li>
            <li><a href="#">Medical Disclaimer</a></li>
          </ul>
        </div>
      </div>
      
      <div className="copyright">
        <p>&copy; 2023 Care Companion. All information is for educational purposes only. Always consult a healthcare professional before taking any medication.</p>
      </div>
    </footer>
  );
};

export default Footer;
