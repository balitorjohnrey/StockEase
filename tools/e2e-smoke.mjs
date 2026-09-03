import { createClient } from '@supabase/supabase-js';

const supabaseUrl =
  process.env.SUPABASE_URL ?? 'https://dscjwdkwubcqxytulqml.supabase.co';
const supabaseKey =
  process.env.SUPABASE_PUBLISHABLE_KEY ??
  process.env.SUPABASE_ANON_KEY ??
  'sb_publishable_n7RFrDOkSD-mBr2PCDhNaA_M2U_j0W8';

const stamp = new Date()
  .toISOString()
  .replaceAll('-', '')
  .replaceAll(':', '')
  .replaceAll('.', '')
  .replace('T', '-')
  .replace('Z', '');
const email = `stockease.e2e+${stamp}@example.com`;
const password = `StockEase-${stamp}!`;
const businessName = `StockEase E2E ${stamp}`;
const sku = `E2E-${stamp}`;

const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

const ok = (message) => console.log(`PASS ${message}`);

const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

const failOnError = ({ error }, action) => {
  if (error) throw new Error(`${action}: ${error.message}`);
};

console.log(`Testing Supabase project: ${supabaseUrl}`);
console.log(`Using disposable account: ${email}`);

const signup = await supabase.auth.signUp({ email, password });
failOnError(signup, 'Sign up failed');
assert(
  signup.data.session,
  'Sign up created a user but did not return a session. Email confirmation is still enabled for new users.',
);
ok('signup returned an authenticated session');

await supabase.auth.signOut();

const login = await supabase.auth.signInWithPassword({ email, password });
failOnError(login, 'Login failed');
assert(login.data.session, 'Login did not return a session');
assert(login.data.user?.email === email, 'Logged-in email did not match');
ok('login returned the expected user session');

const userId = login.data.user.id;

const businessInsert = await supabase
  .from('businesses')
  .insert({ owner_id: userId, name: businessName })
  .select()
  .single();
failOnError(businessInsert, 'Business insert failed');
const business = businessInsert.data;
assert(business?.id, 'Business insert returned no id');
ok('business setup insert works');

const memberFetch = await supabase
  .from('business_members')
  .select()
  .eq('business_id', business.id)
  .eq('user_id', userId)
  .single();
failOnError(memberFetch, 'Business owner membership fetch failed');
assert(memberFetch.data?.role === 'owner', 'Owner membership was not created');
ok('business owner membership trigger works');

const categoryInsert = await supabase
  .from('categories')
  .insert({ business_id: business.id, name: 'Smoke Test' })
  .select()
  .single();
failOnError(categoryInsert, 'Category insert failed');
ok('category insert works');

const productInsert = await supabase
  .from('products')
  .insert({
    business_id: business.id,
    category_id: categoryInsert.data.id,
    name: 'E2E Canned Goods',
    sku,
    cost_price: 25,
    selling_price: 40,
    stock_quantity: 5,
    low_stock_threshold: 2,
  })
  .select()
  .single();
failOnError(productInsert, 'Product insert failed');
const product = productInsert.data;
assert(product?.stock_quantity === 5, 'Product stock did not start at 5');
ok('product insert works');

const restock = await supabase.rpc('restock_product', {
  p_business_id: business.id,
  p_product_id: product.id,
  p_quantity: 3,
  p_reason: 'Automated smoke test',
});
failOnError(restock, 'Restock RPC failed');
assert(restock.data?.new_stock === 8, 'Restock RPC did not return stock 8');
ok('restock RPC works');

const sale = await supabase.rpc('complete_sale', {
  p_business_id: business.id,
  p_items: [{ product_id: product.id, quantity: 2 }],
  p_cash_received: 100,
});
failOnError(sale, 'Complete sale RPC failed');
assert(sale.data?.total_purchase === 80, 'Sale total should be 80');
assert(sale.data?.change === 20, 'Sale change should be 20');
assert(sale.data?.items?.[0]?.quantity === 2, 'Sale item quantity should be 2');
ok('checkout RPC creates receipt with trusted totals');

const productAfterSale = await supabase
  .from('products')
  .select()
  .eq('id', product.id)
  .single();
failOnError(productAfterSale, 'Product refetch after sale failed');
assert(
  productAfterSale.data?.stock_quantity === 6,
  'Product stock should be 6 after restock and sale',
);
ok('checkout decrements inventory');

const salesFetch = await supabase
  .from('sales')
  .select('*, sale_items(*)')
  .eq('business_id', business.id)
  .limit(1);
failOnError(salesFetch, 'Sales fetch failed');
assert(salesFetch.data?.length === 1, 'Sales fetch should return one sale');
assert(
  salesFetch.data[0]?.sale_items?.length === 1,
  'Sales fetch should include one sale item',
);
ok('sales history fetch works');

const expenseInsert = await supabase
  .from('expenses')
  .insert({
    business_id: business.id,
    category: 'Supplies',
    description: 'Automated smoke test',
    amount: 12.5,
  })
  .select()
  .single();
failOnError(expenseInsert, 'Expense insert failed');
ok('expense insert works');

const expenseDelete = await supabase
  .from('expenses')
  .delete()
  .eq('business_id', business.id)
  .eq('id', expenseInsert.data.id);
failOnError(expenseDelete, 'Expense delete failed');
ok('expense delete works');

const deactivate = await supabase
  .from('products')
  .update({ is_active: false })
  .eq('business_id', business.id)
  .eq('id', product.id);
failOnError(deactivate, 'Product deactivate failed');
ok('product deactivate works');

await supabase.auth.signOut();

console.log('\nSmoke test finished successfully.');
console.log(`Test user left in Supabase Auth: ${email}`);
console.log(`Test business left in database: ${businessName}`);
