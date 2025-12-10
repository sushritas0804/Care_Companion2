import React, { useEffect, useState } from 'react';
import { Link, useLocation } from 'react-router-dom';

const Header = () => {
  const [scrolled, setScrolled] = useState(false);
  const location = useLocation();

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 100);
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const isActive = (path) => {
    return location.pathname === path ? 'active' : '';
  };

  return (
    <header className={`header ${scrolled ? 'scrolled' : ''}`} id="header">
      <div className="header-container">
        <Link to="/" className="logo">
          <i className="fas fa-heartbeat logo-icon"></i>
          Care Companion
        </Link>
        
        <nav className="nav-links">
          <Link to="/" className={`nav-link ${isActive('/')}`}>Home</Link>
          <Link to="/categories" className={`nav-link ${isActive('/categories')}`}>Categories</Link>
          <Link to="/adviser" className={`nav-link ${isActive('/adviser')}`}>Adviser</Link>
          <a href="#sources" className="nav-link">Sources</a>
          <a href="#about" className="nav-link">About</a>
        </nav>
        
        <div className="header-actions">
          <Link to="/auth#login">
            <button className="btn btn-outline" id="openLoginModal">Login</button>
          </Link>
          <Link to="/auth#signup">
            <button className="btn btn-primary" id="openSignupModal">Get Started</button>
          </Link>
        </div>
      </div>
    </header>
  );
};

export default Header;
