#!/usr/bin/env node

const { exec } = require('child_process');

console.log('🔍 Checking processes using port 3000...');

// Find processes using port 3000
exec('lsof -ti:3000', (err, stdout, stderr) => {
    if (err) {
        console.log('✅ Port 3000 is free');
        return;
    }
    
    if (stdout.trim()) {
        const pids = stdout.trim().split('\n');
        console.log(`📋 Found processes using port 3000:`, pids);
        
        // Kill each process
        pids.forEach(pid => {
            exec(`kill -9 ${pid}`, (killErr) => {
                if (killErr) {
                    console.log(`❌ Failed to kill process ${pid}`);
                } else {
                    console.log(`✅ Killed process ${pid}`);
                }
            });
        });
        
        setTimeout(() => {
            console.log('🔄 Checking again in 2 seconds...');
            exec('lsof -ti:3000', (err2, stdout2) => {
                if (err2 || !stdout2.trim()) {
                    console.log('✅ Port 3000 is now free!');
                } else {
                    console.log('⚠️  Some processes may still be running');
                }
            });
        }, 2000);
        
    } else {
        console.log('✅ Port 3000 is free');
    }
}); 