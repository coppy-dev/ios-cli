# Coppy Generator

Coppy generator is a companion tool for the Coppy SDK. Its purpose is to
generate swift classes that the Coppy SDK will use in the runtime.

Ideally, this could be a swift package plugin, which will make the setup
a lot simpler. Unfortunately, Apple does not allow swift package plugins
to access the internet, which is essential for the Coppy SDK because we
need to download your latest content from the Coppy app.

Thus, we have this CLI tool to download your content and generate content
classes. It also allows to use this CLI tool if you use a building system other
than Xcode.

## Install

You can use our install script, which will download the CLI, unzip it into `.coppy` directory in your user's home directory, and add it to your terminal config file (bash, zsh, etc.) so it can be correctly called by `coppy` in your terminal. To use this script, just run the below command in your terminal:

```bash
curl -fsSL https://coppy.app/ios/install.sh | bash
```

If you don't want to use the script, you can install it manually. Just download and unzip the archive from our release page. And if you want to call it as `coppy` in your terminal, make sure it is saved in the directory that is added to a `PATH` variable in your terminal.
