import { describe, it, expect, beforeEach } from 'vitest';

// Mock the Clarity contract interactions

describe('License Issuance Contract', () => {
  // Mock state
  let licenses = new Map();
  let licenseIdToProfessional = new Map();
  
  // Reset state before each test
  beforeEach(() => {
    licenses.clear();
    licenseIdToProfessional.clear();
  });
  
  // Mock functions
  function isAuthority(caller: string) {
    // For testing, we'll consider this address as an authority
    return caller === 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';
  }
  
  function issueLicense(
      caller: string,
      licenseId: string,
      professionalId: string,
      profession: string,
      expiryDate: number,
      qualifications: string
  ) {
    if (!isAuthority(caller)) {
      return { type: 'err', value: 100 }; // err-not-authorized
    }
    
    if (licenseIdToProfessional.has(licenseId)) {
      return { type: 'err', value: 101 }; // err-license-exists
    }
    
    licenseIdToProfessional.set(licenseId, { professionalId });
    
    licenses.set(JSON.stringify({ licenseId, professionalId }), {
      authority: caller,
      profession,
      issueDate: 123, // Mock block height
      expiryDate,
      qualifications
    });
    
    return { type: 'ok', value: true };
  }
  
  function getLicenseDetails(licenseId: string) {
    const professionalData = licenseIdToProfessional.get(licenseId);
    if (!professionalData) {
      return null;
    }
    
    const { professionalId } = professionalData;
    return licenses.get(JSON.stringify({ licenseId, professionalId }));
  }
  
  function licenseExists(licenseId: string) {
    return licenseIdToProfessional.has(licenseId);
  }
  
  // Tests
  it('should issue a new license', () => {
    const result = issueLicense(
        'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
        'LIC123',
        'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG',
        'Doctor',
        1000,
        'MD, Board Certified'
    );
    
    expect(result.type).toBe('ok');
    expect(licenseExists('LIC123')).toBe(true);
    
    const details = getLicenseDetails('LIC123');
    expect(details).not.toBeNull();
    expect(details.profession).toBe('Doctor');
    expect(details.qualifications).toBe('MD, Board Certified');
  });
  
  it('should fail to issue a license if not an authority', () => {
    const result = issueLicense(
        'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG', // Not an authority
        'LIC123',
        'ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP',
        'Doctor',
        1000,
        'MD, Board Certified'
    );
    
    expect(result.type).toBe('err');
    expect(result.value).toBe(100); // err-not-authorized
  });
  
  it('should fail to issue a license that already exists', () => {
    issueLicense(
        'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
        'LIC123',
        'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG',
        'Doctor',
        1000,
        'MD, Board Certified'
    );
    
    const result = issueLicense(
        'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
        'LIC123', // Same license ID
        'ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP',
        'Nurse',
        1000,
        'RN'
    );
    
    expect(result.type).toBe('err');
    expect(result.value).toBe(101); // err-license-exists
  });
});
