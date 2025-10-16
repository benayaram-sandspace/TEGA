// Base64 encoded TEGA logo for email templates
// This ensures the logo displays correctly in emails regardless of external URL availability

export const getLogoBase64 = () => {
  // You can generate this by converting your maillogo.jpg to base64
  // For now, using a placeholder - replace with actual base64 of your logo
  return 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCAAoACgDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k=';
};

// Alternative: Use a reliable external CDN URL
export const getLogoUrl = () => {
  return `${process.env.CLIENT_URL || 'http://localhost:3000'}/maillogo.jpg`;
};
