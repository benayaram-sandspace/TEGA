import Job from '../models/Job.js';

// Public: list active jobs and internships
export const getActiveJobs = async (req, res) => {
  try {
    const { 
      postingType, 
      status = 'open', 
      search, 
      limit,
      page = 1
    } = req.query;
    
    // Build the filter
    const filter = { 
      isActive: true,
      status: status === 'all' 
        ? { $in: ['open', 'active'] } 
        : { $in: [status] }
    };
    
    // Add postingType filter if provided (job or internship)
    if (postingType) {
      filter.postingType = postingType;
    } else {
      // Default to showing jobs if no type specified
      filter.postingType = 'job';
    }
    
    // Add search functionality
    if (search) {
      filter.$or = [
        { title: { $regex: search, $options: 'i' } },
        { company: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
        { location: { $regex: search, $options: 'i' } },
        { skills: { $in: [new RegExp(search, 'i')] } }
      ];
    }
    
    // Calculate pagination
    const pageSize = limit ? parseInt(limit) : 10;
    const skip = (parseInt(page) - 1) * pageSize;
    
    // Get total count for pagination
    const total = await Job.countDocuments(filter);
    const totalPages = Math.ceil(total / pageSize);
    
    // Build the query
    let query = Job.find(filter)
      .sort({ isFeatured: -1, createdAt: -1 })
      .skip(skip)
      .limit(pageSize);
    
    const jobs = await query.exec();
    
    // Enhanced response with pagination info
    res.json({ 
      success: true, 
      data: jobs,
      pagination: {
        total,
        totalPages,
        currentPage: parseInt(page),
        hasNextPage: parseInt(page) < totalPages,
        hasPrevPage: parseInt(page) > 1
      },
      count: jobs.length
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      message: 'Failed to fetch jobs',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Public: get single job
export const getJobById = async (req, res) => {
  try {
    const job = await Job.findById(req.params.id);
    if (!job) return res.status(404).json({ success: false, message: 'Job not found' });
    res.json({ success: true, data: job });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch job' });
  }
};

// Admin: get all jobs
export const getAllJobsForAdmin = async (req, res) => {
  try {
    const { search, status, postingType, page = 1, limit = 10 } = req.query;
    const filter = {};
    
    // Add filters if provided
    if (status) filter.status = status;
    if (postingType) filter.postingType = postingType;
    if (search) {
      filter.$or = [
        { title: { $regex: search, $options: 'i' } },
        { company: { $regex: search, $options: 'i' } },
        { location: { $regex: search, $options: 'i' } }
      ];
    }
    
    // Calculate pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);
    
    // Execute query with pagination
    const jobs = await Job.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));
    
    // Get total count for pagination
    const totalJobs = await Job.countDocuments(filter);
    const totalPages = Math.ceil(totalJobs / parseInt(limit));
    
    // Prepare pagination info
    const pagination = {
      currentPage: parseInt(page),
      totalPages,
      totalJobs,
      hasNextPage: parseInt(page) < totalPages,
      hasPrevPage: parseInt(page) > 1
    };
    
    res.json({ 
      success: true, 
      data: jobs,
      pagination
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch jobs' });
  }
};

// Admin: create job
export const createJob = async (req, res) => {
  try {
    // Ensure the job is created with proper status and active flags
    const jobData = {
      ...req.body,
      status: req.body.status || 'open', // Default to 'open' if not specified
      isActive: req.body.isActive !== undefined ? req.body.isActive : true // Default to true if not specified
    };

    const job = await Job.create(jobData);

    res.status(201).json({ success: true, data: job });
  } catch (error) {
    res.status(400).json({ success: false, message: 'Failed to create job' });
  }
};

// Admin: update job
export const updateJob = async (req, res) => {
  try {
    const job = await Job.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!job) return res.status(404).json({ success: false, message: 'Job not found' });
    res.json({ success: true, data: job });
  } catch (error) {
    res.status(400).json({ success: false, message: 'Failed to update job' });
  }
};

// Admin: delete job
export const deleteJob = async (req, res) => {
  try {
    const job = await Job.findByIdAndDelete(req.params.id);
    if (!job) return res.status(404).json({ success: false, message: 'Job not found' });
    res.json({ success: true, message: 'Job deleted' });
  } catch (error) {
    res.status(400).json({ success: false, message: 'Failed to delete job' });
  }
};

// Apply for a job
// This function handles job applications submitted by users.
// It checks if the job exists and is open for applications before processing.
// In a production environment, you would typically create a job application record
// and associate it with the user's profile.
//
// @param {Object} req - The request object
// @param {Object} res - The response object
export const applyForJob = async (req, res) => {
  try {
    
    const jobId = req.params.id;
    const { resume } = req.body;
    
    // Try to get user ID from different possible sources
    const userId = req.user?.id || req.student?._id || req.studentId;

    if (!userId) {
      return res.status(401).json({ 
        success: false,
        message: 'Authentication required' 
      });
    }
    
    if (!jobId) {
      return res.status(400).json({
        success: false,
        message: 'Job ID is required'
      });
    }
    
    if (!resume || !resume.personalInfo) {
      return res.status(400).json({
        success: false,
        message: 'Resume data is required',
        receivedData: JSON.stringify(req.body, null, 2)
      });
    }
    
    // Find the job by ID
    const job = await Job.findById(jobId);
    
    // Check if job exists
    if (!job) {
      return res.status(404).json({ 
        success: false, 
        message: 'Job not found' 
      });
    }

    // Check if job is active and accepting applications
    // Allow applications for jobs with status 'open' or 'active'
    const acceptableStatuses = ['open', 'active'];
    const isStatusAcceptable = acceptableStatuses.includes(job.status);
    // If status is acceptable, allow application regardless of isActive flag
    // (since some jobs might have status 'active' but isActive not set)
    const canApply = isStatusAcceptable;

    if (!canApply) {
      return res.status(400).json({ 
        success: false, 
        message: `This job is not currently accepting applications. Status: ${job.status}` 
      });
    }
    
    // Check if user is authenticated
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required to apply for jobs'
      });
    }
    
    // Check if resume data is provided
    if (!resume || !resume.personalInfo) {
      return res.status(400).json({
        success: false,
        message: 'Resume data is required to apply for this position'
      });
    }
    
    // In a real application, you would:
    // 1. Create an application record in the database
    // 2. Associate it with the user and job
    // 3. Store the resume data
    
    // For now, we'll just return a success response with the application details
    res.status(200).json({ 
      success: true, 
      message: 'Application submitted successfully!',
      data: {
        applicationId: `app_${Date.now()}`,
        jobId: job._id,
        userId,
        status: 'submitted',
        submittedAt: new Date(),
        jobTitle: job.title,
        company: job.company,
        applicantName: resume.personalInfo.fullName || 'Applicant'
      },
      redirectUrl: `/applications/confirmation?jobId=${job._id}`
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      message: 'Failed to submit application',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Admin: update status
export const updateJobStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const job = await Job.findByIdAndUpdate(req.params.id, { status }, { new: true });
    if (!job) return res.status(404).json({ success: false, message: 'Job not found' });
    res.json({ success: true, data: job });
  } catch (error) {
    res.status(400).json({ success: false, message: 'Failed to update job status' });
  }
};
