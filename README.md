# 🔐 Password Generator - Flagsmith Feature Flag Demo

A simple, secure password generator that demonstrates feature flags in action. Perfect for showcasing Flagsmith capabilities in interviews or demos.

## ✨ Features

- **16-character strong passwords** with uppercase, lowercase, numbers, and symbols
- **Copy to clipboard** functionality
- **Strength indicator** showing password strength
- **Feature flag toggles** to demonstrate real-time feature control
- **Beautiful, responsive UI** with smooth animations
- **HTTPS hosting** via AWS S3 + CloudFront

## 🚀 Quick Start

### Local Development
1. Clone or download this repository
2. Open `password-generator.html` in your browser
3. Start demoing feature flags!

### AWS Deployment

#### Prerequisites
- AWS CLI installed and configured
- Terraform installed
- AWS credentials with S3 and CloudFront permissions

#### Deploy to AWS
```bash
# Make scripts executable
chmod +x deploy.sh update.sh

# Deploy to AWS
./deploy.sh
```

#### Update the Website
```bash
# After making changes to password-generator.html
./update.sh
```

#### Clean Up
```bash
# Destroy all AWS resources
terraform destroy
```

## 🏗️ Architecture

- **Frontend**: Single HTML file with embedded CSS/JS
- **Hosting**: AWS S3 static website hosting
- **CDN**: CloudFront for global distribution and HTTPS
- **Infrastructure**: Terraform for infrastructure as code

## 🎛️ Feature Flags Demo

The application includes simulated feature flags that you can toggle in real-time:

1. **Symbols in Password**: Enable/disable special characters
2. **Strength Indicator**: Show/hide the password strength bar
3. **Copy Animation**: Enable/disable smooth transitions

This demonstrates how Flagsmith would work in a production environment.

## 📁 Project Structure

```
simples3/
├── password-generator.html    # Main application
├── main.tf                    # Terraform configuration
├── deploy.sh                  # Deployment script
├── update.sh                  # Update script
└── README.md                  # This file
```

## 🔧 Customization

### Adding New Feature Flags
1. Add the flag to the `featureFlags` object in the JavaScript
2. Create a toggle switch in the HTML
3. Implement the feature logic
4. Update the Terraform if needed

### Styling Changes
- All styles are embedded in the HTML file
- Modify the `<style>` section to change appearance
- The design uses a clean, modern aesthetic suitable for demos

## 🎯 Interview Tips

### Demo Script
1. **Start**: "This is a password generator that demonstrates feature flags"
2. **Show core functionality**: Generate and copy passwords
3. **Demo feature flags**: Toggle switches to show real-time changes
4. **Explain benefits**: No code deployment needed, instant feature control
5. **Discuss use cases**: A/B testing, gradual rollouts, emergency rollbacks

### Key Talking Points
- **Real-time control**: Features can be toggled instantly
- **No deployment**: Changes don't require code updates
- **User targeting**: Can be extended to target specific users
- **Analytics**: Track feature usage and performance
- **Safety**: Easy rollback if issues arise

## 🔒 Security

- Passwords are generated client-side (no server processing)
- HTTPS enforced via CloudFront
- No sensitive data stored or transmitted
- Secure random number generation

## 📞 Support

This is a demo project for showcasing feature flags. For production use, consider:
- Adding proper error handling
- Implementing server-side validation
- Adding user authentication
- Setting up monitoring and logging

---

**Good luck with your Flagsmith interview!** 🚀 