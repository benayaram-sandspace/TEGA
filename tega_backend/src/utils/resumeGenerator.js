import PDFDocument from 'pdfkit';

// Template-specific styles and layouts
const templates = {
  classic: {
    primaryColor: '#2c3e50',
    secondaryColor: '#7f8c8d',
    font: 'Helvetica',
    headerFont: 'Helvetica-Bold',
    sectionSpacing: 15,
    renderHeader: (doc, personalInfo) => {
      // Classic header with centered name and contact info
      doc.fontSize(24)
        .font('Helvetica-Bold')
        .fillColor('#2c3e50')
        .text(personalInfo.fullName || 'Full Name', { align: 'center' });
      
      const contactInfo = [
        personalInfo.email,
        personalInfo.phone,
        personalInfo.location
      ].filter(Boolean).join(' | ');
      
      doc.fontSize(12)
        .font('Helvetica')
        .fillColor('#7f8c8d')
        .text(contactInfo, { align: 'center' });
      
      if (personalInfo.linkedin) {
        doc.fontSize(10)
          .fillColor('blue')
          .text(personalInfo.linkedin, { 
            align: 'center', 
            link: personalInfo.linkedin 
          });
      }
      
      doc.moveDown(2);
    },
    renderSection: (doc, title, items, formatItem) => {
      if (!items || items.length === 0) return;
      
      doc.fontSize(14)
        .font('Helvetica-Bold')
        .fillColor('#2c3e50')
        .text(title.toUpperCase())
        .moveDown(0.5);
      
      items.forEach((item, index) => {
        if (formatItem) {
          formatItem(doc, item);
        } else {
          doc.font('Helvetica')
            .fontSize(12)
            .fillColor('black')
            .text(JSON.stringify(item));
        }
        if (index < items.length - 1) doc.moveDown(0.5);
      });
      
      doc.moveDown(1);
    }
  },
  modern: {
    primaryColor: '#3498db',
    secondaryColor: '#95a5a6',
    font: 'Helvetica',
    headerFont: 'Helvetica-Bold',
    sectionSpacing: 20,
    renderHeader: (doc, personalInfo) => {
      // Modern header with left-aligned name and contact info
      doc.fontSize(28)
        .font('Helvetica-Bold')
        .fillColor('#3498db')
        .text(personalInfo.fullName || 'Full Name');
      
      if (personalInfo.title) {
        doc.fontSize(16)
          .font('Helvetica')
          .fillColor('#95a5a6')
          .text(personalInfo.title);
      }
      
      doc.moveDown(1);
      
      // Contact info in a more structured layout
      const contactInfo = [
        personalInfo.email,
        personalInfo.phone,
        personalInfo.location,
        personalInfo.linkedin
      ].filter(Boolean);
      
      contactInfo.forEach((info, index) => {
        doc.fontSize(10)
          .font('Helvetica')
          .fillColor('#7f8c8d')
          .text(info);
        if (index < contactInfo.length - 1) doc.moveDown(0.3);
      });
      
      doc.moveDown(2);
    },
    renderSection: (doc, title, items, formatItem) => {
      if (!items || items.length === 0) return;
      
      doc.fontSize(16)
        .font('Helvetica-Bold')
        .fillColor('#3498db')
        .text(title.toUpperCase())
        .moveDown(0.5);
      
      items.forEach((item, index) => {
        if (formatItem) {
          formatItem(doc, item);
        } else {
          doc.font('Helvetica')
            .fontSize(11)
            .fillColor('black')
            .text(JSON.stringify(item));
        }
        if (index < items.length - 1) doc.moveDown(0.5);
      });
      
      doc.moveDown(1.5);
    }
  },
  executive: {
    // Executive template styles would go here
  },
  creative: {
    // Creative template styles would go here
  }
};

function addWatermark(doc) {
  const pageWidth = doc.page.width;
  const pageHeight = doc.page.height;
  const centerX = pageWidth / 2;
  const centerY = pageHeight / 2;

  doc.save();
  doc.fontSize(50)
    .fillColor('grey')
    .opacity(0.2)
    .rotate(-45, { origin: [centerX, centerY] })
    .text('TEGA PLATFORM', centerX - 200, centerY);
  doc.restore();
}

function buildResumePdf(resumeData, templateName = 'classic', isWatermarked = false) {
  return new Promise((resolve, reject) => {
    try {
      
      // Check if the requested template exists, fallback to classic if not
      const availableTemplates = Object.keys(templates);
      const templateToUse = availableTemplates.includes(templateName) ? templateName : 'classic';
      
      if (templateName !== templateToUse) {
      }
      
      const template = templates[templateToUse];
      const doc = new PDFDocument({ 
        margin: 50, 
        bufferPages: true,
        info: {
          Title: `${resumeData.personalInfo?.fullName || 'Resume'} - ${templateToUse} Template`,
          Author: 'TEGA Platform',
          Creator: 'TEGA Platform',
          Producer: 'TEGA Platform',
          CreationDate: new Date()
        }
      });
      
      const buffers = [];

      doc.on('data', buffers.push.bind(buffers));
      doc.on('end', () => {
        const pdfData = Buffer.concat(buffers);
        resolve(pdfData);
      });
      doc.on('error', (err) => {
        reject(err);
      });

      // Apply template styles
      const personalInfo = resumeData.personalInfo || {};
      template.renderHeader(doc, personalInfo);
      
      // Render each section using the template
      const sections = [
        { title: 'Summary', items: [resumeData.summary] },
        { title: 'Experience', items: resumeData.experience },
        { title: 'Education', items: resumeData.education },
        { title: 'Skills', items: resumeData.skills },
        { title: 'Projects', items: resumeData.projects },
        { title: 'Certifications', items: resumeData.certifications },
        { title: 'Achievements', items: resumeData.achievements },
        { title: 'Activities', items: resumeData.extracurricularActivities }
      ];
      
      sections.forEach(({ title, items }) => {
        if (items && items.length > 0) {
          template.renderSection(doc, title, items);
        }
      });

      // Add page numbers
      const pages = doc.bufferedPageRange();
      for (let i = 0; i < pages.count; i++) {
        doc.switchToPage(i);
        doc.fontSize(8)
          .fillColor('#7f8c8d')
          .text(
            `Page ${i + 1} of ${pages.count}`,
            doc.page.width - 100,
            doc.page.height - 30
          );
      }

      // Add watermark if needed
      if (isWatermarked) {
        addWatermark(doc);
      }

      doc.end();
    } catch (error) {
      reject(error);
    }
  });
}

export { buildResumePdf };
