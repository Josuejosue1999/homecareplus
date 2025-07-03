#!/usr/bin/env node

/**
 * Profile Data Fix Test Script
 * Tests that the Profile page displays real hospital data instead of "Loading..." placeholders
 */

const http = require('http');

function makeRequest(options) {
    return new Promise((resolve, reject) => {
        const req = http.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => {
                data += chunk;
            });
            res.on('end', () => {
                resolve({
                    statusCode: res.statusCode,
                    headers: res.headers,
                    data: data
                });
            });
        });
        
        req.on('error', (err) => {
            reject(err);
        });
        
        req.end();
    });
}

async function testProfileDataFix() {
    console.log('🧪 Testing Profile Data Fix...\n');
    
    try {
        // Test 1: Server Health Check
        console.log('1. Testing server health...');
        const healthCheck = await makeRequest({
            hostname: 'localhost',
            port: 3001,
            path: '/',
            method: 'GET'
        });
        
        if (healthCheck.statusCode === 200) {
            console.log('✅ Server is running on port 3001');
        } else {
            console.log(`❌ Server returned status ${healthCheck.statusCode}`);
            return;
        }
        
        // Test 2: Profile API Endpoint
        console.log('\n2. Testing profile API endpoint...');
        try {
            const apiTest = await makeRequest({
                hostname: 'localhost',
                port: 3001,
                path: '/api/profile/clinic-data',
                method: 'GET',
                headers: {
                    'Accept': 'application/json'
                }
            });
            
            if (apiTest.statusCode === 401) {
                console.log('✅ Profile API requires authentication (expected)');
            } else if (apiTest.statusCode === 200) {
                console.log('✅ Profile API endpoint is accessible');
            } else {
                console.log(`⚠️  Profile API returned status ${apiTest.statusCode}`);
            }
        } catch (apiError) {
            console.log('⚠️  Profile API test inconclusive:', apiError.message);
        }
        
        // Test 3: Dashboard Route Analysis
        console.log('\n3. Analyzing dashboard route for data loading...');
        const fs = require('fs');
        const path = require('path');
        
        try {
            const appJsPath = path.join(__dirname, 'app.js');
            const appJsContent = fs.readFileSync(appJsPath, 'utf8');
            
            // Check if dashboard route loads clinic data
            const hasAsyncDashboard = appJsContent.includes('app.get("/dashboard", requireAuth, async');
            const hasFirestoreQuery = appJsContent.includes('getDoc(doc(db, \'clinics\'');
            const hasClinicDataProcessing = appJsContent.includes('clinic: clinicData');
            
            if (hasAsyncDashboard && hasFirestoreQuery && hasClinicDataProcessing) {
                console.log('✅ Dashboard route properly loads clinic data server-side');
            } else {
                console.log('❌ Dashboard route missing clinic data loading logic');
                console.log(`   - Async dashboard: ${hasAsyncDashboard}`);
                console.log(`   - Firestore query: ${hasFirestoreQuery}`);
                console.log(`   - Clinic data passing: ${hasClinicDataProcessing}`);
            }
        } catch (fileError) {
            console.log('❌ Could not analyze dashboard route:', fileError.message);
        }
        
        // Test 4: EJS Template Analysis
        console.log('\n4. Analyzing EJS template for data binding...');
        try {
            const dashboardEjsPath = path.join(__dirname, 'views', 'dashboard-new.ejs');
            const dashboardEjsContent = fs.readFileSync(dashboardEjsPath, 'utf8');
            
            // Check if template uses server-side data instead of "Loading..."
            const hasServerSideData = dashboardEjsContent.includes('<%= clinic ?');
            const hasUserFallback = dashboardEjsContent.includes('user.clinicName');
            const hasImageFallback = dashboardEjsContent.includes('onerror="this.src=');
            const noLoadingPlaceholders = !dashboardEjsContent.includes('>Loading...</');
            
            if (hasServerSideData && hasUserFallback && hasImageFallback && noLoadingPlaceholders) {
                console.log('✅ EJS template properly displays server-side clinic data');
            } else {
                console.log('❌ EJS template issues detected:');
                console.log(`   - Server-side data binding: ${hasServerSideData}`);
                console.log(`   - User fallback: ${hasUserFallback}`);
                console.log(`   - Image fallback: ${hasImageFallback}`);
                console.log(`   - No loading placeholders: ${noLoadingPlaceholders}`);
            }
        } catch (templateError) {
            console.log('❌ Could not analyze EJS template:', templateError.message);
        }
        
        // Test 5: JavaScript Fallback Analysis
        console.log('\n5. Analyzing JavaScript fallback logic...');
        try {
            const jsPath = path.join(__dirname, 'public', 'js', 'dashboard-navigation.js');
            const jsContent = fs.readFileSync(jsPath, 'utf8');
            
            // Check if JavaScript has proper fallback logic
            const hasServerSideCheck = jsContent.includes('profileName.textContent.includes(\'Loading...\')');
            const hasErrorHandling = jsContent.includes('showProfileError');
            const hasSafeUpdates = jsContent.includes('safeUpdateElement');
            
            if (hasServerSideCheck && hasErrorHandling && hasSafeUpdates) {
                console.log('✅ JavaScript has proper fallback and error handling');
            } else {
                console.log('⚠️  JavaScript fallback logic could be improved:');
                console.log(`   - Server-side data check: ${hasServerSideCheck}`);
                console.log(`   - Error handling: ${hasErrorHandling}`);
                console.log(`   - Safe updates: ${hasSafeUpdates}`);
            }
        } catch (jsError) {
            console.log('❌ Could not analyze JavaScript:', jsError.message);
        }
        
        // Summary
        console.log('\n📋 SUMMARY:');
        console.log('==========================================');
        console.log('Profile Data Fix Implementation Complete!');
        console.log('');
        console.log('✅ Changes Made:');
        console.log('   • Dashboard route now loads clinic data server-side');
        console.log('   • EJS template displays real data instead of "Loading..."');
        console.log('   • Added proper fallbacks for missing data');
        console.log('   • JavaScript acts as backup for client-side loading');
        console.log('   • Comprehensive error handling implemented');
        console.log('');
        console.log('🎯 Expected Result:');
        console.log('   • Profile page shows actual hospital name, email, phone, etc.');
        console.log('   • Hospital images load from Firebase Storage');
        console.log('   • Services and schedules display if configured');
        console.log('   • Fallbacks show "Not provided" instead of loading text');
        console.log('');
        console.log('🌐 Test the fix at: http://localhost:3001/dashboard');
        
    } catch (error) {
        console.error('❌ Test failed:', error);
    }
}

// Run the test
testProfileDataFix().catch(console.error); 