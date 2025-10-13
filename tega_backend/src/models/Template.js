import mongoose from 'mongoose';
const { Schema } = mongoose;

const TemplateSchema = new Schema({
  name: {
    type: String,
    required: true,
    unique: true,
  },
  previewImage: {
    type: String, // URL to the template's preview image
    required: true,
  },
  isPremium: {
    type: Boolean,
    default: false, // By default, templates are free
  },
}, { timestamps: true });

const Template = mongoose.model('Template', TemplateSchema);

export default Template;
