import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://idfpjdichesettvmfrtz.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_4ugFIrqp8pLkzE31JVUXVQ_8AcCasXs';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
