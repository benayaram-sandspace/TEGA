import mongoose from 'mongoose';
import RealTimeCourse from '../models/RealTimeCourse.js';
import dotenv from 'dotenv';

dotenv.config();

const createSampleRealTimeCourse = async () => {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Create a sample real-time course
    const sampleCourse = new RealTimeCourse({
      title: "Modern React Development",
      description: "Learn modern React development with hooks, context, and real-time features. This comprehensive course covers everything from basics to advanced concepts.",
      shortDescription: "Master React with modern patterns and real-time features",
      
      // Visual Elements
      thumbnail: "https://via.placeholder.com/400x225/3b82f6/ffffff?text=React+Course",
      banner: "https://via.placeholder.com/1200x400/1e40af/ffffff?text=Modern+React+Development",
      previewVideo: "https://via.placeholder.com/800x450/ef4444/ffffff?text=Preview+Video",
      
      // Instructor Info
      instructor: {
        name: "John Doe",
        avatar: "https://via.placeholder.com/100x100/10b981/ffffff?text=JD",
        bio: "Senior React Developer with 8+ years of experience",
        socialLinks: {
          linkedin: "https://linkedin.com/in/johndoe",
          twitter: "https://twitter.com/johndoe",
          website: "https://johndoe.dev"
        }
      },
      
      // Pricing
      price: 2999,
      originalPrice: 4999,
      currency: "INR",
      isFree: false,
      
      // Course Details
      level: "Intermediate",
      category: "Web Development",
      tags: ["React", "JavaScript", "Frontend", "Hooks", "Context"],
      
      // Duration & Content
      estimatedDuration: {
        hours: 12,
        minutes: 30
      },
      totalLectures: 8,
      totalQuizzes: 3,
      totalMaterials: 5,
      
      // Real-time Features
      isLive: false,
      liveViewers: 0,
      
      // Engagement Metrics
      enrollmentCount: 0,
      completionRate: 0,
      averageRating: 0,
      totalRatings: 0,
      
      // Real-time Analytics
      realTimeStats: {
        currentViewers: 0,
        totalWatchTime: 0,
        engagementScore: 0,
        lastUpdated: new Date()
      },
      
      // Course Content
      modules: [
        {
          id: "module-1",
          title: "Getting Started with React",
          description: "Introduction to React and modern development practices",
          order: 1,
          isUnlocked: true,
          unlockCondition: "immediate",
          lectures: [
            {
              id: "lecture-1",
              title: "Introduction to React",
              description: "Learn the fundamentals of React and why it's popular",
              type: "video",
              order: 1,
              duration: 1800, // 30 minutes
              videoContent: {
                r2Url: "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4",
                fileSize: 1048576,
                resolution: "1280x720",
                format: "mp4",
                thumbnail: "https://via.placeholder.com/320x180/3b82f6/ffffff?text=React+Intro"
              },
              materials: [
                {
                  id: "material-1",
                  name: "React Basics.pdf",
                  type: "pdf",
                  r2Url: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf",
                  fileSize: 13264,
                  downloadCount: 0
                }
              ],
              isPreview: true,
              isActive: true
            },
            {
              id: "lecture-2",
              title: "Setting up Development Environment",
              description: "Configure your development environment for React",
              type: "video",
              order: 2,
              duration: 1200, // 20 minutes
              videoContent: {
                r2Url: "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4",
                fileSize: 2097152,
                resolution: "1280x720",
                format: "mp4",
                thumbnail: "https://via.placeholder.com/320x180/10b981/ffffff?text=Setup+Env"
              },
              materials: [
                {
                  id: "material-2",
                  name: "Environment Setup Guide.pdf",
                  type: "pdf",
                  r2Url: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf",
                  fileSize: 13264,
                  downloadCount: 0
                }
              ],
              isPreview: false,
              isActive: true
            }
          ]
        },
        {
          id: "module-2",
          title: "React Hooks Deep Dive",
          description: "Master React hooks for modern functional components",
          order: 2,
          isUnlocked: false,
          unlockCondition: "previous_complete",
          lectures: [
            {
              id: "lecture-3",
              title: "useState and useEffect",
              description: "Learn the most commonly used React hooks",
              type: "video",
              order: 1,
              duration: 2400, // 40 minutes
              videoContent: {
                r2Url: "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_5mb.mp4",
                fileSize: 5242880,
                resolution: "1280x720",
                format: "mp4",
                thumbnail: "https://via.placeholder.com/320x180/f59e0b/ffffff?text=useState+useEffect"
              },
              materials: [
                {
                  id: "material-3",
                  name: "Hooks Cheat Sheet.pdf",
                  type: "pdf",
                  r2Url: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf",
                  fileSize: 13264,
                  downloadCount: 0
                }
              ],
              isPreview: false,
              isActive: true
            },
            {
              id: "lecture-4",
              title: "Hooks Quiz",
              description: "Test your knowledge of React hooks",
              type: "quiz",
              order: 2,
              duration: 900, // 15 minutes
              quizContent: {
                questions: [
                  {
                    id: "q1",
                    question: "What is the purpose of useState hook?",
                    type: "multiple_choice",
                    options: [
                      "To manage component state",
                      "To handle side effects",
                      "To optimize performance",
                      "To create custom hooks"
                    ],
                    correctAnswer: 0,
                    explanation: "useState is used to manage component state in functional components.",
                    points: 1
                  },
                  {
                    id: "q2",
                    question: "When does useEffect run?",
                    type: "multiple_choice",
                    options: [
                      "Only on component mount",
                      "On every render",
                      "After every render by default",
                      "Only when dependencies change"
                    ],
                    correctAnswer: 2,
                    explanation: "useEffect runs after every render by default, but can be controlled with dependencies.",
                    points: 1
                  }
                ],
                timeLimit: 15,
                passingScore: 70,
                attemptsAllowed: 3,
                shuffleQuestions: false,
                showCorrectAnswers: true
              },
              isPreview: false,
              isActive: true
            }
          ]
        }
      ],
      
      // Real-time Features
      realTimeFeatures: {
        liveChat: {
          enabled: true,
          moderation: true
        },
        progressTracking: {
          enabled: true,
          granularity: "lecture"
        },
        notifications: {
          enabled: true,
          types: ["email", "push", "in_app"]
        },
        socialFeatures: {
          discussionForum: true,
          peerInteraction: true,
          leaderboard: true
        }
      },
      
      // Course Status
      status: "published",
      publishedAt: new Date(),
      
      // SEO
      slug: "modern-react-development",
      metaDescription: "Learn modern React development with real-time features and interactive learning",
      keywords: ["React", "JavaScript", "Frontend", "Web Development", "Hooks"],
      
      // Creator
      createdBy: new mongoose.Types.ObjectId() // You'll need to replace this with actual admin ID
    });

    await sampleCourse.save();
    console.log('✅ Sample real-time course created successfully!');
    console.log(`Course ID: ${sampleCourse._id}`);
    console.log(`Course Title: ${sampleCourse.title}`);
    console.log(`Course Slug: ${sampleCourse.slug}`);
    console.log(`Access URL: http://localhost:3000/course/${sampleCourse._id}`);

  } catch (error) {
    console.error('❌ Error creating sample course:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
};

// Run the script
createSampleRealTimeCourse();
