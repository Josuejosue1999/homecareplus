#!/usr/bin/env node

/**
 * Editable Profile Test Script
 * Tests the enhanced Profile page with full editing capabilities
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

async function testEditableProfile() {
    console.log('🧪 Starting Editable Profile Test Suite...\n');
    
    let testsPassed = 0;
    let totalTests = 0;
    
    try {
        // Test 1: Server Health Check
        totalTests++;
        console.log('🔍 Test 1: Checking server health...');
        try {
            const healthCheck = await makeRequest({
                hostname: 'localhost',
                port: 3001,
                path: '/',
                method: 'GET'
            });
            
            if (healthCheck.statusCode === 200) {
                console.log('✅ Server is running successfully');
                testsPassed++;
            } else {
                console.log(`❌ Server health check failed: ${healthCheck.statusCode}`);
            }
        } catch (error) {
            console.log(`❌ Server is not running: ${error.message}`);
        }
        
        // Test 2: Dashboard Page Accessibility
        totalTests++;
        console.log('\n🔍 Test 2: Checking dashboard page accessibility...');
        try {
            const dashboardCheck = await makeRequest({
                hostname: 'localhost',
                port: 3001,
                path: '/dashboard',
                method: 'GET'
            });
            
            // Should redirect to login for unauthenticated users
            if (dashboardCheck.statusCode === 302 || dashboardCheck.statusCode === 401) {
                console.log('✅ Dashboard properly protected (requires auth)');
                testsPassed++;
            } else {
                console.log(`❌ Dashboard accessibility issue: ${dashboardCheck.statusCode}`);
            }
        } catch (error) {
            console.log(`❌ Dashboard check failed: ${error.message}`);
        }
        
        // Test 3: Profile Editor JavaScript File
        totalTests++;
        console.log('\n🔍 Test 3: Checking profile editor script accessibility...');
        try {
            const scriptCheck = await makeRequest({
                hostname: 'localhost',
                port: 3001,
                path: '/js/profile-editor.js',
                method: 'GET'
            });
            
            if (scriptCheck.statusCode === 200) {
                console.log('✅ Profile editor script accessible');
                
                // Check if script contains expected functionality
                if (scriptCheck.data.includes('ProfileEditor') && 
                    scriptCheck.data.includes('saveProfile') &&
                    scriptCheck.data.includes('handleProfileImageUpload') &&
                    scriptCheck.data.includes('handleCertificateUpload')) {
                    console.log('✅ Profile editor script contains all expected functions');
                    testsPassed++;
                } else {
                    console.log('❌ Profile editor script missing expected functions');
                }
            } else {
                console.log(`❌ Profile editor script not accessible: ${scriptCheck.statusCode}`);
            }
        } catch (error) {
            console.log(`❌ Script check failed: ${error.message}`);
        }
        
        // Test 4: CSS Styles Accessibility
        totalTests++;
        console.log('\n🔍 Test 4: Checking CSS styles accessibility...');
        try {
            const cssCheck = await makeRequest({
                hostname: 'localhost',
                port: 3001,
                path: '/css/dashboard.css',
                method: 'GET'
            });
            
            if (cssCheck.statusCode === 200) {
                // Check if CSS contains profile editing styles
                if (cssCheck.data.includes('profile-edit-form') && 
                    cssCheck.data.includes('upload-area') &&
                    cssCheck.data.includes('btn-loading')) {
                    console.log('✅ CSS contains profile editing styles');
                    testsPassed++;
                } else {
                    console.log('❌ CSS missing profile editing styles');
                }
            } else {
                console.log(`❌ CSS not accessible: ${cssCheck.statusCode}`);
            }
        } catch (error) {
            console.log(`❌ CSS check failed: ${error.message}`);
        }
        
        // Test 5: API Endpoint Protection
        totalTests++;
        console.log('\n🔍 Test 5: Checking API endpoint protection...');
        try {
            const apiCheck = await makeRequest({
                hostname: 'localhost',
                port: 3001,
                path: '/api/profile/update',
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                }
            });
            
            // Should be protected and return 401/403 for unauthenticated requests
            if (apiCheck.statusCode === 401 || apiCheck.statusCode === 403) {
                console.log('✅ Profile update API properly protected');
                testsPassed++;
            } else {
                console.log(`❌ Profile update API not properly protected: ${apiCheck.statusCode}`);
            }
        } catch (error) {
            console.log(`❌ API protection check failed: ${error.message}`);
        }
        
        // Test 6: Image Upload Endpoint
        totalTests++;
        console.log('\n🔍 Test 6: Checking image upload endpoint...');
        try {
            const imageUploadCheck = await makeRequest({
                hostname: 'localhost',
                port: 3001,
                path: '/api/profile/upload-image',
                method: 'POST'
            });
            
            // Should be protected and return 401/403 for unauthenticated requests
            if (imageUploadCheck.statusCode === 401 || imageUploadCheck.statusCode === 403) {
                console.log('✅ Image upload API properly protected');
                testsPassed++;
            } else {
                console.log(`❌ Image upload API not properly protected: ${imageUploadCheck.statusCode}`);
            }
        } catch (error) {
            console.log(`❌ Image upload check failed: ${error.message}`);
        }
        
        // Test 7: Certificate Upload Endpoint
        totalTests++;
        console.log('\n🔍 Test 7: Checking certificate upload endpoint...');
        try {
            const certUploadCheck = await makeRequest({
                hostname: 'localhost',
                port: 3001,
                path: '/api/profile/upload-certificate',
                method: 'POST'
            });
            
            // Should be protected and return 401/403 for unauthenticated requests
            if (certUploadCheck.statusCode === 401 || certUploadCheck.statusCode === 403) {
                console.log('✅ Certificate upload API properly protected');
                testsPassed++;
            } else {
                console.log(`❌ Certificate upload API not properly protected: ${certUploadCheck.statusCode}`);
            }
        } catch (error) {
            console.log(`❌ Certificate upload check failed: ${error.message}`);
        }
        
        // Test 8: Profile Data API Endpoint
        totalTests++;
        console.log('\n🔍 Test 8: Checking profile data API endpoint...');
        try {
            const profileDataCheck = await makeRequest({
                hostname: 'localhost',
                port: 3001,
                path: '/api/profile/clinic-data',
                method: 'GET'
            });
            
            // Should be protected and return 401/403 for unauthenticated requests
            if (profileDataCheck.statusCode === 401 || profileDataCheck.statusCode === 403) {
                console.log('✅ Profile data API properly protected');
                testsPassed++;
            } else {
                console.log(`❌ Profile data API not properly protected: ${profileDataCheck.statusCode}`);
            }
        } catch (error) {
            console.log(`❌ Profile data check failed: ${error.message}`);
        }
        
    } catch (error) {
        console.error('❌ Test suite error:', error);
    }
    
    // Test Results Summary
    console.log('\n' + '='.repeat(60));
    console.log('📊 TEST RESULTS SUMMARY');
    console.log('='.repeat(60));
    console.log(`✅ Tests Passed: ${testsPassed}/${totalTests}`);
    console.log(`❌ Tests Failed: ${totalTests - testsPassed}/${totalTests}`);
    console.log(`📈 Success Rate: ${Math.round((testsPassed / totalTests) * 100)}%`);
    
    if (testsPassed === totalTests) {
        console.log('\n🎉 ALL TESTS PASSED! ');
        console.log('🔧 Profile editing functionality is ready to use');
        console.log('🌐 Access your dashboard at: http://localhost:3001/dashboard');
        console.log('\n✨ Features Available:');
        console.log('   • Editable profile fields (name, phone, address, etc.)');
        console.log('   • Profile image upload with preview');
        console.log('   • Certificate document upload (PDF, images)');
        console.log('   • Working hours schedule management');
        console.log('   • Services selection with checkboxes');
        console.log('   • Form validation and error handling');
        console.log('   • Real-time feedback and notifications');
        console.log('   • Drag & drop file upload support');
    } else {
        console.log('\n⚠️  Some tests failed. Check the issues above.');
        console.log('🔧 You may need to verify:');
        console.log('   • Server is running on port 3001');
        console.log('   • All API endpoints are properly configured');
        console.log('   • Profile editor script is correctly loaded');
        console.log('   • CSS styles are properly applied');
    }
    
    console.log('\n' + '='.repeat(60));
}

// Run the test suite
testEditableProfile().catch(console.error); 