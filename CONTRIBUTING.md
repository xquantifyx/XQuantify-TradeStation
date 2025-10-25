# Contributing to XQuantify TradeStation

Thank you for your interest in contributing to XQuantify TradeStation! We welcome contributions from the community.

## 🎯 Ways to Contribute

### 1. Report Bugs
- Check if the bug has already been reported in [Issues](https://github.com/yourusername/xquantify-tradestation/issues)
- If not, create a new issue with a descriptive title
- Include steps to reproduce, expected behavior, and actual behavior
- Add system information (OS, Docker version, etc.)

### 2. Suggest Features
- Open an issue with the `enhancement` label
- Clearly describe the feature and its use case
- Explain how it would benefit users

### 3. Improve Documentation
- Fix typos, clarify instructions
- Add examples and use cases
- Improve code comments
- Translate documentation

### 4. Add Broker Support
- Add new broker configurations to `brokers.json`
- Test the installation thoroughly
- Document any broker-specific requirements
- Update BROKERS.md

### 5. Submit Code
- Fix bugs
- Implement new features
- Improve performance
- Enhance security

---

## 🚀 Getting Started

### Development Setup

1. **Fork the repository**
   ```bash
   # Click "Fork" on GitHub, then:
   git clone https://github.com/YOUR_USERNAME/xquantify-tradestation.git
   cd xquantify-tradestation
   ```

2. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/bug-description
   ```

3. **Set up development environment**
   ```bash
   # Make scripts executable
   chmod +x install.sh uninstall.sh scripts/*.sh

   # Test installation
   ./install.sh
   ```

4. **Make your changes**
   - Follow the coding standards (see below)
   - Test your changes thoroughly
   - Update documentation if needed

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "Description of changes"
   ```

6. **Push and create PR**
   ```bash
   git push origin feature/your-feature-name
   # Then create a Pull Request on GitHub
   ```

---

## 📝 Coding Standards

### Shell Scripts

- Use `#!/bin/bash` shebang
- Set `set -e` for error handling
- Use meaningful variable names (UPPERCASE for environment variables)
- Add comments for complex logic
- Use functions for reusable code
- Include error messages with `print_error` function

**Example:**
```bash
#!/bin/bash
set -e

# Function to check Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker not found"
        return 1
    fi
    print_success "Docker found"
}
```

### Dockerfile

- Group related RUN commands to reduce layers
- Use `--no-install-recommends` for apt-get
- Clean up package manager caches
- Use specific versions when possible
- Add comments explaining non-obvious steps

### Docker Compose

- Use version 3.8 or higher
- Include labels for all services
- Set restart policies appropriately
- Use health checks
- Document environment variables

### Documentation

- Use clear, concise language
- Include code examples
- Add screenshots when helpful
- Keep formatting consistent
- Update table of contents if applicable

---

## 🧪 Testing Guidelines

### Before Submitting PR

1. **Test installation**
   ```bash
   ./uninstall.sh  # Clean up
   ./install.sh    # Test fresh install
   ```

2. **Test core functionality**
   ```bash
   make status     # Check services
   make logs       # View logs
   make health     # Health check
   ```

3. **Test scaling**
   ```bash
   make scale N=2
   make status
   make scale N=1
   ```

4. **Test with different brokers**
   ```bash
   ./scripts/switch-broker.sh
   # Test with at least 2 different brokers
   ```

5. **Test uninstall**
   ```bash
   ./uninstall.sh
   # Verify clean removal
   ```

### Test Checklist

- [ ] Fresh installation works
- [ ] Services start successfully
- [ ] MT5 accessible via browser
- [ ] Scaling works
- [ ] Logs are readable
- [ ] Backup/restore functions
- [ ] Uninstall removes everything
- [ ] Documentation is updated
- [ ] No sensitive data in commits

---

## 🔧 Adding a New Broker

### Step-by-Step Guide

1. **Find the MT5 installer URL**
   - Visit broker's website
   - Find MT5 download page
   - Copy direct download link

2. **Test the installer URL**
   ```bash
   wget -O test.exe "INSTALLER_URL"
   # Verify download works
   ```

3. **Add to brokers.json**
   ```json
   {
     "brokers": {
       "your_broker": {
         "name": "Your Broker Name",
         "installer_url": "https://broker.com/mt5setup.exe",
         "description": "Short description of the broker",
         "auto_login_support": true
       }
     }
   }
   ```

4. **Test the broker**
   ```bash
   # Edit .env
   BROKER=your_broker

   # Build and test
   make build
   make start
   ```

5. **Update documentation**
   - Add to BROKERS.md
   - Add to README.md broker table
   - Document any special requirements

6. **Create PR**
   - Include test results
   - Add screenshots if possible
   - Mention broker support in PR description

---

## 📋 Pull Request Process

### Before Submitting

1. **Update documentation**
   - README.md if adding features
   - BROKERS.md if adding brokers
   - INSTALL.md if changing installation
   - Code comments

2. **Test thoroughly**
   - Follow testing guidelines above
   - Test on clean system if possible
   - Verify backwards compatibility

3. **Commit messages**
   - Use clear, descriptive messages
   - Reference issues if applicable
   - Follow format: `type: description`

   Examples:
   - `feat: add support for Broker XYZ`
   - `fix: resolve Docker build cache issue`
   - `docs: update installation instructions`
   - `refactor: simplify scale.sh script`

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Broker addition
- [ ] Performance improvement

## Testing Done
- [ ] Fresh installation
- [ ] Existing installation upgrade
- [ ] Scaling functionality
- [ ] Backup/restore
- [ ] Documentation accuracy

## Screenshots (if applicable)
Add screenshots here

## Checklist
- [ ] Code follows project standards
- [ ] Documentation updated
- [ ] Tests pass
- [ ] No breaking changes (or documented)
```

### Review Process

1. Automated checks will run (if configured)
2. Maintainers will review your code
3. Address any feedback
4. Once approved, PR will be merged

---

## 🐛 Bug Report Template

When reporting bugs, please include:

```markdown
## Bug Description
Clear description of the bug

## Steps to Reproduce
1. Run command X
2. Observe Y
3. Error occurs

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- OS: Ubuntu 22.04
- Docker version: 20.10.21
- Docker Compose version: 2.15.1
- Broker: XM Global
- Installation method: ./install.sh

## Logs
```
Paste relevant logs here
```

## Additional Context
Any other information
```

---

## 💡 Feature Request Template

```markdown
## Feature Description
Clear description of the proposed feature

## Use Case
Why is this feature needed? Who benefits?

## Proposed Solution
How could this be implemented?

## Alternatives Considered
Other approaches you've thought about

## Additional Context
Mockups, examples, references
```

---

## 🎨 Code Style

### Bash

```bash
# Good
check_docker() {
    local docker_version
    docker_version=$(docker --version)
    print_info "Docker version: $docker_version"
}

# Bad
checkDocker() {
dockerVersion=$(docker --version)
echo "Docker version: $dockerVersion"
}
```

### Makefiles

```makefile
# Good
build:
	@echo "Building XQuantify TradeStation..."
	docker-compose build

# Bad
build:
	docker-compose build
```

---

## 📞 Getting Help

### Questions?

- Open a [Discussion](https://github.com/yourusername/xquantify-tradestation/discussions)
- Check existing [Issues](https://github.com/yourusername/xquantify-tradestation/issues)
- Read the [documentation](README.md)

### Need Support?

- Email: support@xquantify.com
- GitHub Issues for bugs
- GitHub Discussions for questions

---

## 🏆 Recognition

Contributors will be:
- Listed in [CONTRIBUTORS.md](CONTRIBUTORS.md)
- Mentioned in release notes
- Acknowledged in documentation

---

## 📜 Code of Conduct

### Our Standards

- Be respectful and inclusive
- Accept constructive criticism
- Focus on what's best for the community
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Publishing private information
- Unprofessional conduct

### Enforcement

Violations may result in:
1. Warning
2. Temporary ban
3. Permanent ban

Report issues to: conduct@xquantify.com

---

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

## ✨ Thank You!

Your contributions make XQuantify TradeStation better for everyone. We appreciate your time and effort!

**Happy Contributing!** 🚀
