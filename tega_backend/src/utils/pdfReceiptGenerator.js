import PDFDocument from 'pdfkit';

export const generateServerPDFReceipt = (transaction, user) => {
  // Create new PDF document
  const doc = new PDFDocument({
    size: 'A4',
    margins: {
      top: 50,
      bottom: 50,
      left: 50,
      right: 50
    }
  });

  // Set up colors
  const primaryColor = '#2563eb'; // Blue
  const secondaryColor = '#64748b'; // Gray
  const successColor = '#10b981'; // Green
  
  // Company branding
  const companyName = 'TEGA';
  const companyTagline = 'Technology Education & Growth Academy';
  
  // Header section with blue background
  doc.rect(0, 0, 595, 80)
     .fill(primaryColor);
  
  // Company name (white text on blue background)
  doc.fillColor('white')
     .fontSize(28)
     .font('Helvetica-Bold')
     .text(companyName, 50, 30);
  
  // Company tagline (white text, smaller)
  doc.fontSize(12)
     .font('Helvetica')
     .text(companyTagline, 50, 55);
  
  // Receipt title
  doc.fillColor('black')
     .fontSize(20)
     .font('Helvetica-Bold')
     .text('PAYMENT RECEIPT', 50, 120);
  
  // Receipt number and date
  doc.fontSize(11)
     .font('Helvetica')
     .fillColor(secondaryColor)
     .text(`Receipt No: ${transaction.transactionId}`, 50, 150)
     .text(`Date: ${formatDate(transaction.date)}`, 50, 165);
  
  // Customer information section
  doc.fillColor('black')
     .fontSize(14)
     .font('Helvetica-Bold')
     .text('BILL TO:', 50, 200);
  
  doc.fontSize(11)
     .font('Helvetica')
     .text(user.firstName || user.username || 'Student', 50, 220)
     .text(user.email || '', 50, 235);
  
  if (user.phone) {
    doc.text(user.phone, 50, 250);
  }
  
  // Transaction details section
  doc.fontSize(14)
     .font('Helvetica-Bold')
     .text('TRANSACTION DETAILS:', 50, 280);
  
  // Create table for transaction details
  const tableData = [
    ['Description', 'Amount'],
    [transaction.courseName, `₹${transaction.amount}`],
    ['Payment Method', transaction.paymentMethod.toUpperCase()],
    ['Status', transaction.status.toUpperCase()],
    ['Transaction ID', transaction.transactionId]
  ];
  
  // Draw table
  let yPosition = 300;
  const tableWidth = 495; // 595 - 100 (margins)
  const col1Width = 300;
  const col2Width = 195;
  
  tableData.forEach((row, index) => {
    if (index === 0) {
      // Header row
      doc.rect(50, yPosition - 15, tableWidth, 20)
         .fill('#f0f0f0');
      doc.fillColor('black')
         .font('Helvetica-Bold')
         .fontSize(11);
    } else {
      doc.fillColor('black')
         .font('Helvetica')
         .fontSize(10);
    }
    
    doc.text(row[0], 55, yPosition - 5);
    doc.text(row[1], 355, yPosition - 5);
    
    // Draw table borders
    doc.strokeColor('#ddd')
       .lineWidth(0.5)
       .rect(50, yPosition - 15, tableWidth, 20)
       .stroke();
    
    yPosition += 20;
  });
  
  // Total amount section
  yPosition += 20;
  doc.rect(50, yPosition - 15, tableWidth, 25)
     .fill(primaryColor);
  
  doc.fillColor('white')
     .fontSize(16)
     .font('Helvetica-Bold')
     .text('TOTAL AMOUNT PAID:', 55, yPosition - 5)
     .text(`₹${transaction.amount}`, 355, yPosition - 5);
  
  // Status indicator
  yPosition += 40;
  doc.fillColor('black')
     .fontSize(11)
     .font('Helvetica');
  
  if (transaction.status === 'completed') {
    doc.fillColor(successColor)
       .font('Helvetica-Bold')
       .text('✓ PAYMENT SUCCESSFUL', 50, yPosition);
    doc.fillColor('black')
       .font('Helvetica')
       .text('Your payment has been processed successfully.', 50, yPosition + 15)
       .text('You now have access to the course content.', 50, yPosition + 30);
  } else if (transaction.status === 'pending') {
    doc.fillColor('#f59e0b')
       .font('Helvetica-Bold')
       .text('⏳ PAYMENT PENDING', 50, yPosition);
    doc.fillColor('black')
       .font('Helvetica')
       .text('Your payment is being processed.', 50, yPosition + 15)
       .text('You will receive confirmation once completed.', 50, yPosition + 30);
  } else {
    doc.fillColor('#ef4444')
       .font('Helvetica-Bold')
       .text('✗ PAYMENT FAILED', 50, yPosition);
    doc.fillColor('black')
       .font('Helvetica')
       .text('Your payment could not be processed.', 50, yPosition + 15)
       .text('Please try again or contact support.', 50, yPosition + 30);
  }
  
  // Footer section
  yPosition += 60;
  doc.strokeColor('#ccc')
     .lineWidth(1)
     .moveTo(50, yPosition)
     .lineTo(545, yPosition)
     .stroke();
  
  yPosition += 20;
  doc.fillColor(secondaryColor)
     .fontSize(10)
     .font('Helvetica')
     .text('Thank you for choosing TEGA!', 50, yPosition)
     .text('For support, contact: support@tega.com', 50, yPosition + 15)
     .text('Visit us at: www.tega.com', 50, yPosition + 30);
  
  // Terms and conditions
  yPosition += 50;
  doc.fontSize(8)
     .text('Terms & Conditions:', 50, yPosition)
     .text('• This receipt serves as proof of payment', 50, yPosition + 12)
     .text('• Course access is granted upon successful payment', 50, yPosition + 24)
     .text('• Refunds are subject to our refund policy', 50, yPosition + 36)
     .text('• For disputes, contact support within 7 days', 50, yPosition + 48);
  
  // Add QR code placeholder
  yPosition += 70;
  doc.rect(450, yPosition, 50, 50)
     .fill('#f0f0f0')
     .stroke();
  doc.fillColor(secondaryColor)
     .fontSize(8)
     .text('QR Code', 460, yPosition + 20)
     .text('(Future)', 460, yPosition + 30);
  
  return doc;
};

// Helper function to format date
const formatDate = (date) => {
  try {
    const dateObj = new Date(date);
    if (isNaN(dateObj.getTime())) {
      return 'Invalid Date';
    }
    return new Intl.DateTimeFormat('en-IN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    }).format(dateObj);
  } catch (error) {
    return 'Invalid Date';
  }
};
