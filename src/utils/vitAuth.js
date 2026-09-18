/**
 * VIT Vellore Student Email Domain Verification & Identity Parser
 * Target Domain: @vitstudent.ac.in
 * Format: name.surname[admissionYear]@vitstudent.ac.in
 * Example: vismay.shrouty2025@vitstudent.ac.in
 */

/**
 * Calculates student academic standing and year number based on admission year
 * Default reference year: 2026
 */
export function calculateAcademicStanding(admissionYear, currentYear = 2026) {
  if (!admissionYear || isNaN(admissionYear)) {
    return {
      yearNumber: null,
      label: 'Student',
      isGraduated: false
    };
  }

  const yearDiff = (currentYear - admissionYear) + 1;

  if (yearDiff === 1) {
    return { yearNumber: 1, label: '1st Year (Freshman)', isGraduated: false };
  } else if (yearDiff === 2) {
    return { yearNumber: 2, label: '2nd Year (Sophomore)', isGraduated: false };
  } else if (yearDiff === 3) {
    return { yearNumber: 3, label: '3rd Year (Junior)', isGraduated: false };
  } else if (yearDiff === 4) {
    return { yearNumber: 4, label: '4th Year (Senior)', isGraduated: false };
  } else if (yearDiff > 4) {
    return { yearNumber: yearDiff, label: 'Alumnus / Post-Grad', isGraduated: true };
  } else {
    return { yearNumber: 1, label: 'Incoming Student', isGraduated: false };
  }
}

/**
 * Parses and validates an email string strictly for VIT Vellore students.
 * Extracts firstName, lastName, fullName, admissionYear, and academicStanding.
 */
export function parseVitEmail(email) {
  if (!email || typeof email !== 'string') {
    return {
      isValidVit: false,
      error: 'Invalid or missing email address'
    };
  }

  const cleanEmail = email.trim().toLowerCase();

  // 1. Verify exact @vitstudent.ac.in domain
  if (!cleanEmail.endsWith('@vitstudent.ac.in')) {
    return {
      isValidVit: false,
      error: 'Access restricted: Only verified VIT students (@vitstudent.ac.in) are permitted'
    };
  }

  const localPart = cleanEmail.replace('@vitstudent.ac.in', '');

  // 2. Regex matching: firstName.lastName[4-digit-year] or firstName[4-digit-year]
  const pattern = /^([a-z]+)(?:\.([a-z]+))?(\d{4})$/;
  const match = localPart.match(pattern);

  const capitalize = (str) => {
    if (!str) return '';
    return str.charAt(0).toUpperCase() + str.slice(1);
  };

  if (!match) {
    // Robust fallback: extract any 4-digit number as admission year, rest as name
    const yearMatch = localPart.match(/(\d{4})/);
    const admissionYear = yearMatch ? parseInt(yearMatch[1], 10) : 2025;
    const rawName = localPart.replace(/\d+/g, '').replace(/[._-]/g, ' ').trim();
    const formattedName = rawName
      ? rawName.split(/\s+/).map(capitalize).join(' ')
      : 'VIT Student';

    const standing = calculateAcademicStanding(admissionYear);

    return {
      isValidVit: true,
      email: cleanEmail,
      firstName: formattedName.split(' ')[0] || 'VIT',
      lastName: formattedName.split(' ').slice(1).join(' ') || 'Student',
      fullName: formattedName,
      admissionYear,
      academicStanding: standing.label,
      academicYearNumber: standing.yearNumber,
      isGraduated: standing.isGraduated
    };
  }

  const firstNameRaw = match[1];
  const lastNameRaw = match[2] || '';
  const admissionYear = parseInt(match[3], 10);

  const firstName = capitalize(firstNameRaw);
  const lastName = capitalize(lastNameRaw);
  const fullName = lastName ? `${firstName} ${lastName}` : firstName;
  const standing = calculateAcademicStanding(admissionYear);

  return {
    isValidVit: true,
    email: cleanEmail,
    firstName,
    lastName,
    fullName,
    admissionYear,
    academicStanding: standing.label,
    academicYearNumber: standing.yearNumber,
    isGraduated: standing.isGraduated
  };
}

/**
 * Generates a mock or plausible VIT registration number for accounts created via Google OAuth
 * Format: [YY][BRANCH][4-DIGIT-SERIAL] e.g. 25BCE1842
 */
export function generateVitRegNumber(admissionYear = 2025, branch = 'BCE') {
  const shortYear = (admissionYear % 100).toString().padStart(2, '0');
  const randomSerial = Math.floor(1000 + Math.random() * 9000);
  return `${shortYear}${branch}${randomSerial}`;
}

/**
 * Verifies a Google OAuth ID token.
 * Uses Google's standard tokeninfo endpoint if token is live, or handles dev test tokens.
 */
export async function verifyGoogleIdToken(idToken, fallbackPayload = null) {
  if (!idToken) {
    throw new Error('Google ID token is required');
  }

  // Handle mock / local dev / integration test tokens
  if (idToken.startsWith('mock_') || idToken === 'test_google_token' || fallbackPayload) {
    return {
      email: fallbackPayload?.email || 'vismay.shrouty2025@vitstudent.ac.in',
      name: fallbackPayload?.name || 'Vismay Shrouty',
      picture: fallbackPayload?.picture || 'https://lh3.googleusercontent.com/a/default-user',
      googleId: fallbackPayload?.googleId || `google_sub_${Date.now()}`
    };
  }

  // Online verification against Google's public tokeninfo endpoint
  try {
    const res = await fetch(`https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`);
    if (!res.ok) {
      const errBody = await res.text();
      throw new Error(`Google token validation failed: ${errBody}`);
    }
    const tokenInfo = await res.json();
    return {
      email: tokenInfo.email,
      name: tokenInfo.name,
      picture: tokenInfo.picture,
      googleId: tokenInfo.sub
    };
  } catch (err) {
    throw new Error(`Unable to verify Google token: ${err.message}`);
  }
}
