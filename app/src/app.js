// Jenkins CI/CD — S3 + CloudFront Demo App
// Author: Sri Charan Garikapati

document.addEventListener('DOMContentLoaded', () => {
    const buildInfo = document.getElementById('build-info');
    if (buildInfo) {
        buildInfo.textContent = `v${Date.now()} — Deployed via Jenkins`;
    }
    console.log('✅ App loaded — deployed via Jenkins CI/CD to AWS S3 + CloudFront');
});
