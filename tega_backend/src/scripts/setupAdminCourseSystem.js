import mongoose from 'mongoose';
import RealTimeCourse from '../models/RealTimeCourse.js';
import RealTimeProgress from '../models/RealTimeProgress.js';

const setupAdminCourseSystem = async () => {
  try {
    // Check if we have any existing courses
    const existingCourses = await RealTimeCourse.countDocuments();
    if (existingCourses === 0) {
      const sampleCourse = new RealTimeCourse({
        title: 'Modern React Development',
        description: 'Learn modern React development with hooks, context, and real-time features. This comprehensive course covers everything from basics to advanced concepts.',
        shortDescription: 'Master React with modern patterns and real-time features',
        price: 2999,
        originalPrice: 4999,
        level: 'Intermediate',
        category: 'Web Development',
        tags: ['React', 'JavaScript', 'Frontend'],
        isFree: false,
        status: 'published',
        instructor: {
          name: 'John Doe',
          bio: 'Senior React Developer with 10+ years of experience in building scalable web applications.',
          avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&h=100&fit=crop&crop=face'
        },
        modules: [
          {
            id: 'module-1',
            title: 'Getting Started with React',
            description: 'Learn the fundamentals of React and set up your development environment.',
            order: 1,
            lectures: [
              {
                id: 'lecture-1',
                title: 'Introduction to React (Preview)',
                description: 'Learn the fundamentals of React and why it\'s popular in modern web development.',
                duration: 1800, // 30 minutes
                order: 1,
                type: 'video',
                isPreview: true,
                videoContent: {
                  r2Url: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
                  fileSize: 1048576, // 1MB
                  resolution: '1920x1080',
                  format: 'video/mp4'
                }
              },
              {
                id: 'lecture-2',
                title: 'Setting up Development Environment',
                description: 'Configure your development environment for React development.',
                duration: 1200, // 20 minutes
                order: 2,
                type: 'video',
                isPreview: false,
                videoContent: {
                  r2Url: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4',
                  fileSize: 2097152, // 2MB
                  resolution: '1920x1080',
                  format: 'video/mp4'
                }
              },
              {
                id: 'lecture-3',
                title: 'React Components Deep Dive',
                description: 'Master React components and their lifecycle methods.',
                duration: 2400, // 40 minutes
                order: 3,
                type: 'video',
                isPreview: false,
                videoContent: {
                  r2Url: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_5mb.mp4',
                  fileSize: 5242880, // 5MB
                  resolution: '1920x1080',
                  format: 'video/mp4'
                }
              }
            ]
          },
          {
            id: 'module-2',
            title: 'React Hooks Mastery',
            description: 'Learn modern React patterns with hooks.',
            order: 2,
            lectures: [
              {
                id: 'lecture-4',
                title: 'useState and useEffect',
                description: 'Learn the most commonly used React hooks.',
                duration: 2400, // 40 minutes
                order: 1,
                type: 'video',
                isPreview: false,
                videoContent: {
                  r2Url: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_5mb.mp4',
                  fileSize: 5242880, // 5MB
                  resolution: '1920x1080',
                  format: 'video/mp4'
                }
              },
              {
                id: 'lecture-5',
                title: 'Custom Hooks',
                description: 'Create your own custom hooks for reusable logic.',
                duration: 1800, // 30 minutes
                order: 2,
                type: 'video',
                isPreview: false,
                videoContent: {
                  r2Url: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_3mb.mp4',
                  fileSize: 3145728, // 3MB
                  resolution: '1920x1080',
                  format: 'video/mp4'
                }
              }
            ]
          }
        ],
        enrollmentCount: 1247,
        averageRating: 4.8,
        totalRatings: 156,
        createdAt: new Date(),
        updatedAt: new Date()
      });

      await sampleCourse.save();
    }

    // Check database connection and models
    const courseCount = await RealTimeCourse.countDocuments();
    const progressCount = await RealTimeProgress.countDocuments();
    // Test sample queries
    const publishedCourses = await RealTimeCourse.find({ status: 'published' });
    const coursesWithPreview = await RealTimeCourse.find({
      'modules.lectures.isPreview': true
    });
  } catch (error) {
    process.exit(1);
  }
};

// Run the setup
setupAdminCourseSystem().then(() => {
  process.exit(0);
}).catch((error) => {
  process.exit(1);
});
