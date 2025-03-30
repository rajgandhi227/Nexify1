-- Create the jobs table with all required fields to match our JobType interface
CREATE TABLE IF NOT EXISTS public.jobs (
  id BIGINT PRIMARY KEY,
  title TEXT NOT NULL,
  companyName TEXT NOT NULL,
  companyLogo TEXT,
  location TEXT NOT NULL,
  jobType TEXT NOT NULL,
  salary TEXT,
  category TEXT NOT NULL,
  description TEXT NOT NULL,
  experienceLevel TEXT NOT NULL,
  featured BOOLEAN DEFAULT false,
  postedBy TEXT NOT NULL,
  postedTime TEXT NOT NULL,
  createdAt TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updatedAt TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Add necessary indexes for better performance
CREATE INDEX IF NOT EXISTS idx_jobs_postedBy ON public.jobs(postedBy);
CREATE INDEX IF NOT EXISTS idx_jobs_category ON public.jobs(category);
CREATE INDEX IF NOT EXISTS idx_jobs_location ON public.jobs(location);
CREATE INDEX IF NOT EXISTS idx_jobs_jobType ON public.jobs(jobType);
CREATE INDEX IF NOT EXISTS idx_jobs_created_at ON public.jobs(createdAt DESC);

-- Enable Row Level Security
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;

-- Create policies for access control
-- Anyone can read jobs
CREATE POLICY "Anyone can read jobs" 
ON public.jobs FOR SELECT 
USING (true);

-- Only authenticated users can insert jobs
CREATE POLICY "Authenticated users can insert jobs" 
ON public.jobs FOR INSERT 
TO authenticated 
USING (true);

-- Users can only update their own jobs
CREATE POLICY "Users can update their own jobs" 
ON public.jobs FOR UPDATE 
TO authenticated 
USING (postedBy = auth.uid());

-- Users can only delete their own jobs
CREATE POLICY "Users can delete their own jobs" 
ON public.jobs FOR DELETE 
TO authenticated 
USING (postedBy = auth.uid());

-- Enable realtime subscriptions
ALTER PUBLICATION supabase_realtime ADD TABLE public.jobs;

-- Add a database trigger to update the updatedAt timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW."updatedAt" = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_jobs_updated_at
BEFORE UPDATE ON public.jobs
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

-- Add a function to ensure jobs have proper timestamps even if not provided
CREATE OR REPLACE FUNCTION ensure_job_timestamps()
RETURNS TRIGGER AS $$
BEGIN
    -- Set createdAt if not provided
    IF NEW."createdAt" IS NULL THEN
        NEW."createdAt" = now();
    END IF;
    
    -- Always set updatedAt to now for new records
    NEW."updatedAt" = now();
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER ensure_jobs_timestamps
BEFORE INSERT ON public.jobs
FOR EACH ROW
EXECUTE PROCEDURE ensure_job_timestamps();

-- IMPORTANT: Run this SQL in your Supabase SQL Editor to set up proper job persistence
-- CAUTION: Run this to reset the table (will delete all data)
-- DROP TABLE IF EXISTS public.jobs; 