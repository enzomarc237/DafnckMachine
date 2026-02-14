const fs = require('fs');
const path = require('path');

// Configuration
const WORKFLOW_DIR = '01_Machine/01_Workflow';
const OLD_PATH = '01_Machine/04_Documentation/Doc/';
const NEW_PATH = '01_Machine/04_Documentation/vision/';

// Function to recursively find all markdown files
function findMarkdownFiles(dir) {
    const files = [];
    
    function traverse(currentDir) {
        const items = fs.readdirSync(currentDir);
        
        for (const item of items) {
            const fullPath = path.join(currentDir, item);
            const stat = fs.statSync(fullPath);
            
            if (stat.isDirectory()) {
                traverse(fullPath);
            } else if (item.endsWith('.md')) {
                files.push(fullPath);
            }
        }
    }
    
    traverse(dir);
    return files;
}

// Function to update file paths in content
function updateFilePaths(content) {
    // Replace all instances of the old path with the new path
    return content.replace(new RegExp(OLD_PATH.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g'), NEW_PATH);
}

// Main execution
function main() {
    console.log('🔧 Starting documentation path correction...');
    console.log(`📁 Scanning directory: ${WORKFLOW_DIR}`);
    console.log(`🔄 Converting: ${OLD_PATH} → ${NEW_PATH}`);
    
    // Find all markdown files
    const markdownFiles = findMarkdownFiles(WORKFLOW_DIR);
    console.log(`📄 Found ${markdownFiles.length} markdown files to process`);
    
    let updatedCount = 0;
    let totalReplacements = 0;
    
    // Process each file
    for (const filePath of markdownFiles) {
        try {
            const content = fs.readFileSync(filePath, 'utf8');
            const updatedContent = updateFilePaths(content);
            
            // Count replacements in this file
            const replacements = (content.match(new RegExp(OLD_PATH.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g')) || []).length;
            
            if (replacements > 0) {
                fs.writeFileSync(filePath, updatedContent, 'utf8');
                updatedCount++;
                totalReplacements += replacements;
                console.log(`✅ Updated ${filePath} (${replacements} replacements)`);
            }
        } catch (error) {
            console.error(`❌ Error processing ${filePath}:`, error.message);
        }
    }
    
    console.log('\n📊 SUMMARY:');
    console.log(`📄 Total files processed: ${markdownFiles.length}`);
    console.log(`✅ Files updated: ${updatedCount}`);
    console.log(`🔄 Total path replacements: ${totalReplacements}`);
    console.log(`📁 Unchanged files: ${markdownFiles.length - updatedCount}`);
    
    if (updatedCount > 0) {
        console.log('\n🎉 Documentation path correction completed successfully!');
        console.log(`All references to "${OLD_PATH}" have been updated to "${NEW_PATH}"`);
    } else {
        console.log('\n✨ No files needed updating - all paths are already correct!');
    }
}

// Execute the script
main();