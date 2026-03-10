import { useState, useEffect } from 'react';
import { CheckSquare, Activity, Focus, Settings, Plus, Trash2, LogOut, Check } from 'lucide-react';
import { supabase } from './lib/supabase';

interface FocusCategory {
  id: string;
  name: string;
  description: string;
  domains: string[];
}

interface TodoRecord {
  id: string;
  user_id: string;
  title: string;
  is_completed: boolean;
  completed_at: string | null;
  sort_date: string | null;
  created_at: string;
}

interface HabitRecord {
  id: string;
  user_id: string;
  name: string;
}

interface HabitCompletionRecord {
  id: string;
  habit_id: string;
  user_id: string;
  completed_date: string;
}

export default function App() {
  const [activeTab, setActiveTab] = useState('todos');
  
  // Auth State
  const [user, setUser] = useState<any>(null);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [authLoading, setAuthLoading] = useState(false);
  const [authError, setAuthError] = useState('');

  // Data State
  const [todos, setTodos] = useState<TodoRecord[]>([]);
  const [newTodoTitle, setNewTodoTitle] = useState('');
  const [habits, setHabits] = useState<HabitRecord[]>([]);
  const [completions, setCompletions] = useState<HabitCompletionRecord[]>([]);

  // Focus Categories State
  const [categories, setCategories] = useState<FocusCategory[]>([]);
  const [isAddingCategory, setIsAddingCategory] = useState(false);
  const [newCategoryName, setNewCategoryName] = useState('');
  const [newCategoryDesc, setNewCategoryDesc] = useState('');
  const [newCategoryDomains, setNewCategoryDomains] = useState('');

  // Duration State
  const [selectedDuration, setSelectedDuration] = useState<number | 'custom'>(25);
  const [customHours, setCustomHours] = useState(0);
  const [customMinutes, setCustomMinutes] = useState(45);

  // Initialize Auth & Storage
  useEffect(() => {
    // Check active session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
      if (session?.user) {
        fetchUserData(session.user.id);
      }
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
      if (session?.user) {
        fetchUserData(session.user.id);
      } else {
        setTodos([]);
        setHabits([]);
        setCompletions([]);
      }
    });

    // Load Focus storage
    chrome.storage.local.get(['focusCategories', 'lastDuration', 'lastCustomHours', 'lastCustomMinutes'], (res) => {
      if (res.focusCategories) {
        setCategories(res.focusCategories as FocusCategory[]);
      } else {
        const defaultCategory: FocusCategory = {
          id: '1',
          name: 'Work',
          description: 'Blocks distractor',
          domains: ['youtube.com', 'facebook.com', 'reddit.com', 'twitter.com', 'instagram.com']
        };
        setCategories([defaultCategory]);
        chrome.storage.local.set({ focusCategories: [defaultCategory] });
      }
      
      if (res.lastDuration) setSelectedDuration(res.lastDuration as number | 'custom');
      if (res.lastCustomHours !== undefined && res.lastCustomHours !== null) setCustomHours(res.lastCustomHours as number);
      if (res.lastCustomMinutes !== undefined && res.lastCustomMinutes !== null) setCustomMinutes(res.lastCustomMinutes as number);
    });

    return () => subscription.unsubscribe();
  }, []);

  // Fetch Supabase Data
  const fetchUserData = async (userId: string) => {
    // Fetch Todos
    const { data: todosData } = await supabase
      .from('TodoRecord')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });
    if (todosData) setTodos(todosData);

    // Fetch Habits
    const { data: habitsData } = await supabase
      .from('HabitRecord')
      .select('*')
      .eq('user_id', userId);
    if (habitsData) setHabits(habitsData);

    // Fetch today's completions
    const today = new Date().toISOString().split('T')[0];
    const { data: compsData } = await supabase
      .from('HabitCompletionRecord')
      .select('*')
      .eq('user_id', userId)
      .eq('completed_date', today);
    if (compsData) setCompletions(compsData);
  };

  // Listen to Realtime Todo updates
  useEffect(() => {
    if (!user) return;
    const channel = supabase
      .channel('schema-db-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'TodoRecord', filter: `user_id=eq.${user.id}` }, () => {
        fetchUserData(user.id);
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'HabitCompletionRecord', filter: `user_id=eq.${user.id}` }, () => {
        fetchUserData(user.id);
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    }
  }, [user]);

  // Auth Methods
  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    setAuthLoading(true);
    setAuthError('');
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) setAuthError(error.message);
    setAuthLoading(false);
  };

  const handleSignOut = async () => {
    await supabase.auth.signOut();
  };

  // Todo Methods
  const handleAddTodo = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTodoTitle.trim() || !user) return;
    
    const newTodo = {
      user_id: user.id,
      title: newTodoTitle.trim(),
      is_completed: false,
      sort_date: new Date().toISOString()
    };
    
    setNewTodoTitle('');
    await supabase.from('TodoRecord').insert(newTodo);
  };

  const toggleTodo = async (todo: TodoRecord) => {
    const isCompleted = !todo.is_completed;
    const completedAt = isCompleted ? new Date().toISOString() : null;
    
    // Optimistic update
    setTodos(todos.map(t => t.id === todo.id ? { ...t, is_completed: isCompleted, completed_at: completedAt } : t));
    
    await supabase
      .from('TodoRecord')
      .update({ is_completed: isCompleted, completed_at: completedAt })
      .eq('id', todo.id);
  };

  const deleteTodo = async (id: string) => {
    setTodos(todos.filter(t => t.id !== id));
    await supabase.from('TodoRecord').delete().eq('id', id);
  };

  // Habit Methods
  const toggleHabit = async (habitId: string) => {
    if (!user) return;
    const today = new Date().toISOString().split('T')[0];
    const existingComp = completions.find(c => c.habit_id === habitId && c.completed_date === today);

    if (existingComp) {
      // Optimistic delete
      setCompletions(completions.filter(c => c.id !== existingComp.id));
      await supabase.from('HabitCompletionRecord').delete().eq('id', existingComp.id);
    } else {
      const newComp = {
        habit_id: habitId,
        user_id: user.id,
        completed_date: today
      };
      // For optimistic insert we just rely on the realtime fetch as we don't know the ID yet
      // Alternatively, we could fetch right after insert
      await supabase.from('HabitCompletionRecord').insert(newComp);
      fetchUserData(user.id); 
    }
  };

  // Focus Methods
  const saveCategories = (newCategories: FocusCategory[]) => {
    setCategories(newCategories);
    chrome.storage.local.set({ focusCategories: newCategories });
  };

  const handleAddCategory = () => {
    if (!newCategoryName.trim() || !newCategoryDomains.trim()) return;
    const domainList = newCategoryDomains.split(',').map(d => d.trim()).filter(d => d);
    if (domainList.length === 0) return;

    const newCategory: FocusCategory = {
      id: Date.now().toString(),
      name: newCategoryName.trim(),
      description: newCategoryDesc.trim() || 'Custom block rules',
      domains: domainList
    };

    saveCategories([...categories, newCategory]);
    setNewCategoryName('');
    setNewCategoryDesc('');
    setNewCategoryDomains('');
    setIsAddingCategory(false);
  };

  const startSession = (category: FocusCategory) => {
    let finalDuration = 25;
    if (selectedDuration === 'custom') {
      finalDuration = (customHours * 60) + customMinutes;
      if (finalDuration <= 0) {
        alert("Please set a time greater than 0 minutes.");
        return;
      }
    } else {
      finalDuration = selectedDuration as number;
    }

    chrome.runtime.sendMessage({
      type: 'START_FOCUS_SESSION',
      payload: { domains: category.domains, durationMinutes: finalDuration }
    }, (response) => {
      if (response && response.status === 'started') {
        alert(`Started Focus Session: ${category.name} for ${finalDuration}m`);
      }
    });
  };

  return (
    <div className="flex flex-col h-full bg-slate-100">
      {/* Header */}
      <div className="pt-6 pb-4 px-6 bg-white border-b border-gray-200">
        <h1 className="text-xl font-semibold text-gray-900">
          {activeTab === 'todos' && 'Todos'}
          {activeTab === 'habits' && 'Habits'}
          {activeTab === 'focus' && 'Focus'}
          {activeTab === 'account' && 'Account'}
        </h1>
      </div>

      {/* Main Content Area */}
      <div className="flex-1 overflow-y-auto w-full">
        {!user && activeTab !== 'focus' ? (
          <div className="p-6 h-full flex flex-col items-center justify-center">
            <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mb-4">
              <Settings className="text-blue-600" size={32} />
            </div>
            <h2 className="text-lg font-bold text-gray-900 mb-2">Sign into Cleansed</h2>
            <p className="text-sm text-center text-gray-500 mb-6">Access your todos and habits synced directly from the iOS app.</p>
            
            <form onSubmit={handleSignIn} className="w-full space-y-3">
              <input 
                type="email" 
                placeholder="Email address" 
                value={email}
                onChange={e => setEmail(e.target.value)}
                className="w-full p-3 border border-gray-200 rounded-lg text-sm focus:outline-blue-500"
                required
              />
              <input 
                type="password" 
                placeholder="Password" 
                value={password}
                onChange={e => setPassword(e.target.value)}
                className="w-full p-3 border border-gray-200 rounded-lg text-sm focus:outline-blue-500"
                required
              />
              {authError && <p className="text-xs text-red-500 text-center">{authError}</p>}
              <button 
                type="submit" 
                disabled={authLoading}
                className="w-full py-3 bg-blue-600 text-white rounded-lg font-medium shadow-sm hover:bg-blue-700 disabled:opacity-50"
              >
                {authLoading ? 'Signing in...' : 'Sign In'}
              </button>
            </form>
          </div>
        ) : (
          <div className="p-4 h-full">
            {activeTab === 'todos' && (
              <div className="flex flex-col h-full">
                <form onSubmit={handleAddTodo} className="mb-4 flex gap-2">
                  <input 
                    type="text" 
                    value={newTodoTitle}
                    onChange={e => setNewTodoTitle(e.target.value)}
                    placeholder="Add a new task..."
                    className="flex-1 p-3 rounded-xl border border-gray-200 text-sm focus:outline-blue-500 shadow-sm"
                  />
                  <button type="submit" className="bg-blue-600 text-white p-3 rounded-xl hover:bg-blue-700 shadow-sm disabled:opacity-50" disabled={!newTodoTitle.trim()}>
                    <Plus size={20} />
                  </button>
                </form>

                <div className="space-y-2 pb-6">
                  {todos.map(todo => (
                    <div key={todo.id} className="p-3 bg-white rounded-xl shadow-sm border border-gray-100 flex items-center gap-3 group">
                      <button 
                        onClick={() => toggleTodo(todo)}
                        className={`w-6 h-6 rounded-full border-2 flex items-center justify-center flex-shrink-0 transition-colors ${todo.is_completed ? 'bg-blue-600 border-blue-600' : 'border-gray-300'}`}
                      >
                        {todo.is_completed && <Check size={14} className="text-white" />}
                      </button>
                      <span className={`flex-1 text-sm font-medium ${todo.is_completed ? 'text-gray-400 line-through' : 'text-gray-700'}`}>
                        {todo.title}
                      </span>
                      <button 
                        onClick={() => deleteTodo(todo.id)}
                        className="text-gray-300 hover:text-red-500 p-1 opacity-0 group-hover:opacity-100 transition-opacity"
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  ))}
                  {todos.length === 0 && (
                     <div className="text-center text-sm text-gray-400 py-10">No tasks remaining!</div>
                  )}
                </div>
              </div>
            )}

            {activeTab === 'habits' && (
              <div className="space-y-3 pb-6">
                {habits.length === 0 ? (
                  <div className="text-center text-sm text-gray-400 py-10">No habits found. Create one in the iOS app to sync here!</div>
                ) : (
                  habits.map(habit => {
                    const isCompletedToday = completions.some(c => c.habit_id === habit.id);
                    return (
                      <div key={habit.id} className="p-4 bg-white rounded-xl shadow-sm border border-gray-100 flex items-center justify-between">
                        <span className="font-semibold text-gray-800">{habit.name}</span>
                        <button 
                          onClick={() => toggleHabit(habit.id)}
                          className={`w-8 h-8 rounded-full flex items-center justify-center transition ${isCompletedToday ? 'bg-green-500 text-white shadow-md shadow-green-200' : 'bg-gray-100 text-gray-400 hover:bg-gray-200'}`}
                        >
                          <Check size={18} />
                        </button>
                      </div>
                    )
                  })
                )}
              </div>
            )}

            {activeTab === 'focus' && (
              <div className="flex flex-col gap-4 pb-6">
                {/* Duration Selector */}
                <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-200">
                  <h3 className="text-sm font-semibold text-gray-800 mb-3">Session Duration</h3>
                  <div className="flex gap-2 mb-3">
                    {[10, 25, 60, 'custom'].map(val => (
                      <button
                        key={val}
                        onClick={() => { setSelectedDuration(val as any); chrome.storage.local.set({ lastDuration: val }); }}
                        className={`flex-1 py-1.5 rounded-md text-xs font-medium transition ${
                          selectedDuration === val ? 'bg-blue-600 text-white' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                        }`}
                      >
                        {val === 60 ? '1h' : val === 'custom' ? 'Custom' : `${val}m`}
                      </button>
                    ))}
                  </div>

                  {selectedDuration === 'custom' && (
                    <div className="flex items-center gap-4 bg-slate-50 p-3 rounded-lg border border-slate-200 justify-center">
                      <div className="flex flex-col items-center">
                        <input 
                          type="number" min="0" max="23" value={customHours}
                          onChange={(e) => { const v = parseInt(e.target.value)||0; setCustomHours(v); chrome.storage.local.set({ lastCustomHours: v }); }}
                          className="w-14 text-center p-1.5 border border-slate-300 rounded font-medium text-lg focus:outline-blue-500"
                        />
                        <span className="text-[10px] text-slate-500 font-medium mt-1 uppercase tracking-wider">Hours</span>
                      </div>
                      <span className="text-xl font-bold text-slate-400 pb-4">:</span>
                      <div className="flex flex-col items-center">
                        <input 
                          type="number" min="0" max="59" value={customMinutes}
                          onChange={(e) => { const v = parseInt(e.target.value)||0; setCustomMinutes(v); chrome.storage.local.set({ lastCustomMinutes: v }); }}
                          className="w-14 text-center p-1.5 border border-slate-300 rounded font-medium text-lg focus:outline-blue-500"
                        />
                        <span className="text-[10px] text-slate-500 font-medium mt-1 uppercase tracking-wider">Mins</span>
                      </div>
                    </div>
                  )}
                </div>

                {/* Category List */}
                {categories.map(category => (
                  <div key={category.id} className="p-4 bg-white rounded-xl border border-gray-200 shadow-sm relative group">
                    <button
                      onClick={() => saveCategories(categories.filter(c => c.id !== category.id))}
                      className="absolute top-4 right-4 text-gray-400 hover:text-red-500 hidden group-hover:block p-1"
                    >
                      <Trash2 size={16} />
                    </button>
                    <h3 className="font-semibold text-gray-900 mb-1 pr-6">{category.name}</h3>
                    <p className="text-xs text-gray-500 mb-3">{category.description}</p>
                    <div className="flex flex-wrap gap-1 mb-4">
                      {category.domains.slice(0, 3).map(d => (
                        <span key={d} className="px-2 py-0.5 bg-gray-100 text-gray-600 rounded text-[10px] truncate max-w-[80px]">{d}</span>
                      ))}
                      {category.domains.length > 3 && (
                        <span className="px-2 py-0.5 bg-gray-100 text-gray-600 rounded text-[10px]">+{category.domains.length - 3}</span>
                      )}
                    </div>
                    <button
                      onClick={() => startSession(category)}
                      className="w-full py-2 bg-blue-600 text-white rounded-lg text-sm font-medium shadow-sm hover:bg-blue-700 transition"
                    >
                      Start Session
                    </button>
                  </div>
                ))}

                {/* Add Category */}
                {isAddingCategory ? (
                  <div className="p-4 bg-blue-50/50 rounded-xl border border-blue-200">
                    <h4 className="text-sm font-semibold text-blue-900 mb-3">New Focus Category</h4>
                    <input type="text" placeholder="Category Name" value={newCategoryName} onChange={e => setNewCategoryName(e.target.value)} className="w-full p-2 text-sm border bg-white rounded-lg mb-2" />
                    <input type="text" placeholder="Description" value={newCategoryDesc} onChange={e => setNewCategoryDesc(e.target.value)} className="w-full p-2 text-sm border bg-white rounded-lg mb-2" />
                    <textarea placeholder="Domains (comma separated)" value={newCategoryDomains} onChange={e => setNewCategoryDomains(e.target.value)} className="w-full p-2 text-sm border bg-white rounded-lg mb-3 h-20" />
                    <div className="flex gap-2">
                      <button onClick={() => setIsAddingCategory(false)} className="flex-1 py-2 bg-white text-gray-600 rounded-lg text-sm font-medium border">Cancel</button>
                      <button onClick={handleAddCategory} disabled={!newCategoryName.trim() || !newCategoryDomains.trim()} className="flex-1 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium disabled:opacity-50">Save</button>
                    </div>
                  </div>
                ) : (
                  <button onClick={() => setIsAddingCategory(true)} className="flex items-center justify-center gap-2 p-4 border-2 border-dashed border-gray-300 rounded-xl text-gray-500 hover:bg-gray-50 hover:text-blue-600 transition">
                    <Plus size={18} />
                    <span className="text-sm font-medium">Add Focus Category</span>
                  </button>
                )}
              </div>
            )}

            {activeTab === 'account' && (
              <div className="space-y-4">
                <div className="p-4 bg-white rounded-xl border border-gray-100">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center font-bold text-lg">
                      {user.email?.charAt(0).toUpperCase()}
                    </div>
                    <div>
                      <h3 className="font-semibold text-gray-900 text-sm truncate w-48">{user.email}</h3>
                      <p className="text-xs text-gray-500">Authenticated Extension</p>
                    </div>
                  </div>
                </div>

                <div className="p-4 bg-white rounded-xl border border-gray-100">
                  <div className="flex items-center justify-between">
                    <span className="font-medium text-sm text-gray-700">Ad Remover</span>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input type="checkbox" className="sr-only peer" onChange={(e) => chrome.runtime.sendMessage({ type: 'TOGGLE_AD_BLOCKER', payload: { enabled: e.target.checked } })} />
                      <div className="w-9 h-5 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-blue-600"></div>
                    </label>
                  </div>
                </div>

                <button onClick={handleSignOut} className="w-full flex items-center justify-center gap-2 py-3 bg-red-50 text-red-600 rounded-xl font-medium mt-6 hover:bg-red-100 transition">
                  <LogOut size={18} /> Sign Out
                </button>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Tab Bar Navigation */}
      <div className="bg-white border-t border-gray-200 px-4 py-2 pb-6 flex justify-between items-center text-xs">
        <button 
          onClick={() => setActiveTab('todos')}
          className={`flex flex-col items-center gap-1 p-2 w-16 ${activeTab === 'todos' ? 'text-blue-600' : 'text-gray-400'}`}
        >
          <CheckSquare size={20} className={activeTab === 'todos' ? 'fill-blue-50' : ''} />
          <span>Todos</span>
        </button>
        <button 
          onClick={() => setActiveTab('habits')}
          className={`flex flex-col items-center gap-1 p-2 w-16 ${activeTab === 'habits' ? 'text-blue-600' : 'text-gray-400'}`}
        >
          <Activity size={20} />
          <span>Habits</span>
        </button>
        <button 
          onClick={() => setActiveTab('focus')}
          className={`flex flex-col items-center gap-1 p-2 w-16 ${activeTab === 'focus' ? 'text-blue-600' : 'text-gray-400'}`}
        >
          <Focus size={20} />
          <span>Focus</span>
        </button>
        <button 
          onClick={() => setActiveTab('account')}
          className={`flex flex-col items-center gap-1 p-2 w-16 ${activeTab === 'account' ? 'text-blue-600' : 'text-gray-400'}`}
        >
          <Settings size={20} />
          <span>Account</span>
        </button>
      </div>
    </div>
  );
}
