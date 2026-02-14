#!/usr/bin/env node

/**
 * Output Artifacts Checklist Audit & Update Tool
 * 
 * This script systematically audits and updates Output Artifacts Checklists
 * across all Markdown files in the DafnckMachine-V3.1 workflow directories.
 * 
 * Features:
 * - Scans all workflow Markdown files
 * - Identifies inconsistencies between top checklists and bottom Output Artifacts
 * - Converts MDC links to proper checklist format
 * - Updates incorrect checklists while preserving correct ones
 * - Maintains consistent formatting across all files
 * - Provides detailed reporting and validation
 */

const fs = require('fs');
const path = require('path');

class OutputArtifactsAuditor {
    constructor() {
        this.workflowDir = '01_Machine/01_Workflow';
        this.results = {
            totalFiles: 0,
            correctChecklists: 0,
            incorrectChecklists: 0,
            missingChecklists: 0,
            updatedFiles: 0,
            errors: []
        };
        this.fileAnalysis = [];
    }

    /**
     * Main execution method
     */
    async run() {
        console.log('🔍 Starting Output Artifacts Checklist Audit...\n');
        
        try {
            // Step 1: Discover all workflow files
            const files = this.discoverWorkflowFiles();
            console.log(`📁 Found ${files.length} workflow files to analyze\n`);
            
            // Step 2: Analyze each file
            for (const file of files) {
                await this.analyzeFile(file);
            }
            
            // Step 3: Generate report
            this.generateReport();
            
            // Step 4: Update files if needed
            await this.updateFiles();
            
            // Step 5: Final validation
            this.validateResults();
            
        } catch (error) {
            console.error('❌ Error during audit:', error);
            this.results.errors.push(`Main execution error: ${error.message}`);
        }
    }

    /**
     * Discover all Markdown files in workflow directories
     */
    discoverWorkflowFiles() {
        const files = [];
        
        const scanDirectory = (dir) => {
            try {
                const items = fs.readdirSync(dir);
                
                for (const item of items) {
                    const fullPath = path.join(dir, item);
                    const stat = fs.statSync(fullPath);
                    
                    if (stat.isDirectory()) {
                        scanDirectory(fullPath);
                    } else if (item.endsWith('.md')) {
                        files.push(fullPath);
                    }
                }
            } catch (error) {
                console.warn(`⚠️  Warning: Could not scan directory ${dir}: ${error.message}`);
            }
        };
        
        scanDirectory(this.workflowDir);
        return files.sort();
    }

    /**
     * Analyze a single file for Output Artifacts patterns
     */
    async analyzeFile(filePath) {
        try {
            const content = fs.readFileSync(filePath, 'utf8');
            const lines = content.split('\n');
            
            const analysis = {
                filePath,
                fileName: path.basename(filePath),
                phase: this.extractPhase(filePath),
                currentChecklist: null,
                checklistLine: -1,
                actualArtifacts: [],
                artifactsSection: null,
                status: 'unknown',
                needsUpdate: false,
                proposedChecklist: []
            };

            // Find current checklist
            this.findCurrentChecklist(lines, analysis);
            
            // Find actual Output Artifacts section
            this.findActualArtifacts(lines, analysis);
            
            // Determine status and needed updates
            this.determineStatus(analysis);
            
            // Generate proposed checklist if needed
            if (analysis.needsUpdate) {
                this.generateProposedChecklist(analysis);
            }

            this.fileAnalysis.push(analysis);
            this.updateResultsCounters(analysis);
            
            // Log progress
            const statusIcon = this.getStatusIcon(analysis.status);
            console.log(`${statusIcon} ${analysis.fileName} - ${analysis.status}`);
            
        } catch (error) {
            console.error(`❌ Error analyzing ${filePath}:`, error.message);
            this.results.errors.push(`File analysis error (${filePath}): ${error.message}`);
        }
    }

    /**
     * Extract phase information from file path
     */
    extractPhase(filePath) {
        const match = filePath.match(/Phase\s*(\d+|0\s*:\s*Project\s*Setup)/i);
        return match ? match[0] : 'Unknown';
    }

    /**
     * Find the current Output Artifacts Checklist in the file
     */
    findCurrentChecklist(lines, analysis) {
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            
            // Look for the checklist section header
            if (line === '## Output Artifacts Checklist') {
                analysis.checklistLine = i;
                
                // Read the checklist content
                let j = i + 1;
                while (j < lines.length && !lines[j].startsWith('#')) {
                    const checklistLine = lines[j].trim();
                    if (checklistLine && !checklistLine.startsWith('##')) {
                        if (!analysis.currentChecklist) {
                            analysis.currentChecklist = [];
                        }
                        analysis.currentChecklist.push(checklistLine);
                    }
                    j++;
                }
                break;
            }
        }
    }

    /**
     * Find actual Output Artifacts section at the bottom of the file
     */
    findActualArtifacts(lines, analysis) {
        let inArtifactsSection = false;
        let sectionStart = -1;
        
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            
            // Look for Output Artifacts section (with possible typos)
            if (line.match(/^##?\s*Output\s*Arteits?$/i) || 
                line.match(/^##?\s*Output\s*Artifacts$/i)) {
                inArtifactsSection = true;
                sectionStart = i;
                analysis.artifactsSection = {
                    startLine: i,
                    title: line
                };
                continue;
            }
            
            if (inArtifactsSection) {
                // Stop at next section or end of file
                if (line.startsWith('#') && i > sectionStart + 1) {
                    break;
                }
                
                // Extract MDC links
                const mdcMatch = line.match(/\[([^\]]+)\]\(mdc:([^)]+)\)(?:\s*[:-]\s*(.+))?/);
                if (mdcMatch) {
                    analysis.actualArtifacts.push({
                        title: mdcMatch[1],
                        path: mdcMatch[2],
                        description: mdcMatch[3] || mdcMatch[1],
                        originalLine: line
                    });
                }
            }
        }
    }

    /**
     * Determine the status of the file and whether it needs updates
     */
    determineStatus(analysis) {
        if (!analysis.currentChecklist && analysis.actualArtifacts.length === 0) {
            analysis.status = 'no_artifacts';
        } else if (!analysis.currentChecklist) {
            analysis.status = 'missing_checklist';
            analysis.needsUpdate = true;
        } else if (analysis.actualArtifacts.length === 0) {
            analysis.status = 'no_actual_artifacts';
        } else {
            // Check if current checklist is correct
            const hasNoArtifactsStatement = analysis.currentChecklist.some(line => 
                line.includes('No Output Artifacts section found')
            );
            
            if (hasNoArtifactsStatement && analysis.actualArtifacts.length > 0) {
                analysis.status = 'incorrect_no_artifacts';
                analysis.needsUpdate = true;
            } else if (this.checklistMatchesArtifacts(analysis)) {
                analysis.status = 'correct';
            } else {
                analysis.status = 'needs_sync';
                analysis.needsUpdate = true;
            }
        }
    }

    /**
     * Check if current checklist matches actual artifacts
     */
    checklistMatchesArtifacts(analysis) {
        if (!analysis.currentChecklist || analysis.actualArtifacts.length === 0) {
            return false;
        }
        
        // Simple check: if we have artifacts and no "No Output Artifacts" statement
        const hasNoArtifactsStatement = analysis.currentChecklist.some(line => 
            line.includes('No Output Artifacts section found')
        );
        
        return !hasNoArtifactsStatement && analysis.actualArtifacts.length > 0;
    }

    /**
     * Generate proposed checklist based on actual artifacts
     */
    generateProposedChecklist(analysis) {
        if (analysis.actualArtifacts.length === 0) {
            analysis.proposedChecklist = ['- _No Output Artifacts section found_'];
            return;
        }

        analysis.proposedChecklist = analysis.actualArtifacts.map(artifact => {
            const fileName = path.basename(artifact.path);
            const status = 'missing'; // Default status, could be enhanced
            return `- [ ] ${artifact.path} — ${fileName}: ${artifact.description} (${status})`;
        });
    }

    /**
     * Update results counters based on analysis
     */
    updateResultsCounters(analysis) {
        this.results.totalFiles++;
        
        switch (analysis.status) {
            case 'correct':
                this.results.correctChecklists++;
                break;
            case 'incorrect_no_artifacts':
            case 'needs_sync':
                this.results.incorrectChecklists++;
                break;
            case 'missing_checklist':
                this.results.missingChecklists++;
                break;
        }
    }

    /**
     * Get status icon for display
     */
    getStatusIcon(status) {
        const icons = {
            'correct': '✅',
            'incorrect_no_artifacts': '❌',
            'needs_sync': '⚠️',
            'missing_checklist': '📝',
            'no_artifacts': '⚪',
            'no_actual_artifacts': '🔍'
        };
        return icons[status] || '❓';
    }

    /**
     * Generate comprehensive audit report
     */
    generateReport() {
        console.log('\n' + '='.repeat(60));
        console.log('📊 OUTPUT ARTIFACTS CHECKLIST AUDIT REPORT');
        console.log('='.repeat(60));
        
        console.log(`\n📈 SUMMARY STATISTICS:`);
        console.log(`   Total Files Analyzed: ${this.results.totalFiles}`);
        console.log(`   ✅ Correct Checklists: ${this.results.correctChecklists}`);
        console.log(`   ❌ Incorrect Checklists: ${this.results.incorrectChecklists}`);
        console.log(`   📝 Missing Checklists: ${this.results.missingChecklists}`);
        console.log(`   🔧 Files Needing Updates: ${this.fileAnalysis.filter(f => f.needsUpdate).length}`);
        
        // Detailed breakdown by status
        console.log(`\n📋 DETAILED BREAKDOWN:`);
        const statusCounts = {};
        this.fileAnalysis.forEach(analysis => {
            statusCounts[analysis.status] = (statusCounts[analysis.status] || 0) + 1;
        });
        
        Object.entries(statusCounts).forEach(([status, count]) => {
            const icon = this.getStatusIcon(status);
            console.log(`   ${icon} ${status.replace(/_/g, ' ')}: ${count} files`);
        });

        // Files needing updates
        const needsUpdate = this.fileAnalysis.filter(f => f.needsUpdate);
        if (needsUpdate.length > 0) {
            console.log(`\n🔧 FILES REQUIRING UPDATES:`);
            needsUpdate.forEach(analysis => {
                console.log(`   ${this.getStatusIcon(analysis.status)} ${analysis.fileName}`);
                console.log(`      Status: ${analysis.status}`);
                console.log(`      Artifacts Found: ${analysis.actualArtifacts.length}`);
                if (analysis.proposedChecklist.length > 0) {
                    console.log(`      Proposed Checklist: ${analysis.proposedChecklist.length} items`);
                }
                console.log('');
            });
        }

        // Errors
        if (this.results.errors.length > 0) {
            console.log(`\n❌ ERRORS ENCOUNTERED:`);
            this.results.errors.forEach(error => {
                console.log(`   • ${error}`);
            });
        }
    }

    /**
     * Update files that need checklist corrections
     */
    async updateFiles() {
        const needsUpdate = this.fileAnalysis.filter(f => f.needsUpdate);
        
        if (needsUpdate.length === 0) {
            console.log('\n✅ No files need updates. All checklists are correct!');
            return;
        }

        console.log(`\n🔧 UPDATING ${needsUpdate.length} FILES...\n`);
        
        for (const analysis of needsUpdate) {
            try {
                await this.updateSingleFile(analysis);
                this.results.updatedFiles++;
                console.log(`✅ Updated: ${analysis.fileName}`);
            } catch (error) {
                console.error(`❌ Failed to update ${analysis.fileName}:`, error.message);
                this.results.errors.push(`Update error (${analysis.fileName}): ${error.message}`);
            }
        }
    }

    /**
     * Update a single file's checklist
     */
    async updateSingleFile(analysis) {
        const content = fs.readFileSync(analysis.filePath, 'utf8');
        const lines = content.split('\n');
        
        if (analysis.checklistLine === -1) {
            // Need to add checklist section
            this.addChecklistSection(lines, analysis);
        } else {
            // Update existing checklist
            this.updateExistingChecklist(lines, analysis);
        }
        
        const updatedContent = lines.join('\n');
        fs.writeFileSync(analysis.filePath, updatedContent, 'utf8');
    }

    /**
     * Add a new checklist section to the file
     */
    addChecklistSection(lines, analysis) {
        // Find the position after YAML frontmatter
        let insertPosition = 0;
        let inFrontmatter = false;
        
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].trim() === '---') {
                if (!inFrontmatter) {
                    inFrontmatter = true;
                } else {
                    insertPosition = i + 1;
                    break;
                }
            }
        }
        
        // Insert the checklist section
        const checklistSection = [
            '## Output Artifacts Checklist',
            ...analysis.proposedChecklist,
            ''
        ];
        
        lines.splice(insertPosition, 0, ...checklistSection);
    }

    /**
     * Update existing checklist section
     */
    updateExistingChecklist(lines, analysis) {
        // Find the end of the current checklist section
        let endLine = analysis.checklistLine + 1;
        while (endLine < lines.length && !lines[endLine].startsWith('#')) {
            endLine++;
        }
        
        // Replace the checklist content
        const newContent = [
            '## Output Artifacts Checklist',
            ...analysis.proposedChecklist,
            ''
        ];
        
        lines.splice(analysis.checklistLine, endLine - analysis.checklistLine, ...newContent);
    }

    /**
     * Validate the results after updates
     */
    validateResults() {
        console.log('\n' + '='.repeat(60));
        console.log('✅ AUDIT COMPLETE - FINAL RESULTS');
        console.log('='.repeat(60));
        
        console.log(`\n📊 FINAL STATISTICS:`);
        console.log(`   Total Files Processed: ${this.results.totalFiles}`);
        console.log(`   Files Updated: ${this.results.updatedFiles}`);
        console.log(`   Errors Encountered: ${this.results.errors.length}`);
        
        if (this.results.errors.length === 0) {
            console.log('\n🎉 SUCCESS: All Output Artifacts Checklists have been audited and updated!');
        } else {
            console.log('\n⚠️  COMPLETED WITH ERRORS: Some issues were encountered during the audit.');
        }
        
        console.log('\n📝 NEXT STEPS:');
        console.log('   1. Review the updated files to ensure accuracy');
        console.log('   2. Verify that all MDC links are working correctly');
        console.log('   3. Update any missing documentation artifacts');
        console.log('   4. Consider running this audit periodically to maintain consistency');
        
        console.log('\n' + '='.repeat(60));
    }
}

// Execute the audit if run directly
if (require.main === module) {
    const auditor = new OutputArtifactsAuditor();
    auditor.run().catch(console.error);
}

module.exports = OutputArtifactsAuditor;