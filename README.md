WinBinder
=========

WinBinder - The native Windows binding for PHP 8.

[![Build status](https://ci.appveyor.com/api/projects/status/github/Bearsampp/php_winbinder?svg=true&branch=main)](https://ci.appveyor.com/project/Bear/php-winbinder) PHP 8.3.29 x64

What is WinBinder?
==================

WinBinder is an open source extension to PHP, the script programming language. It allows PHP programmers to easily build native Windows applications, producing quick and rewarding results with minimum effort. Even short scripts with a few dozen lines can generate a useful program, thanks to the power and flexibility of PHP.

[Docs](https://crispy-computing-machine.github.io/Winbinder-Docs/)

[Examples](https://github.com/crispy-computing-machine/Winbinder-Examples)

[IDE Stub File](https://gist.github.com/crispy-computing-machine/ee4e94ba5e4870a7907535185af14ba0)

PHP Build Compatibility
=======================

- PHP 7.* ❌ (unsupported)
- PHP 8.3.29 ✅ (x64, x86, TS, NTS)

(For older PHP version compatibility please see PECL website for old .dll's)

Latest Features & Updates
=========================

[Wiki - New features!](https://github.com/Bearsampp/php_winbinder/wiki/New-Features-Functions)

Reporting Bugs
==============

Report them via github [issues](https://github.com/Bearsampp/php_winbinder/issues).

About
=====

Forked from [Wagy](https://github.com/wagy/WinBinder) for PHP7 support

**Updated for PHP 8.3 compatibility.**

# ⚠️ DO NOT USE IN PRODUCTION!

# ⚠️ No warranty provided!

## AppVeyor Deployment Setup

If you are forking this repository and want automated GitHub Releases to work, you **MUST** set up your GitHub Personal Access Token (PAT) in AppVeyor:

1.  **Generate a GitHub PAT**: Go to your GitHub Settings -> Developer settings -> Personal access tokens (classic) and generate a token with the **`repo`** scope.
2.  **Add to AppVeyor**: 
    - Open your project in AppVeyor.
    - Go to **Settings** -> **Environment**.
    - Click **Add variable**.
    - **Name**: `GH_PAT` (must be exactly this name).
    - **Value**: Paste your GitHub token.
    - Click the **lock icon** next to the value to encrypt it.
    - Click **Save** at the bottom of the page.

*Note: Do not set the token in the "Deployment" or "Environments" sections of AppVeyor, as they are used for different purposes.*

## Security and Trust

When using the `php_winbinder.dll`, you might encounter a Windows "Unknown Publisher" warning. This occurs because the DLL is currently not digitally signed.

### Why this happens
Windows uses a feature called SmartScreen and User Account Control (UAC) to verify the origin of executable files and libraries. Since this is an open-source project and the binaries are often built on automated CI/CD systems without a paid developer certificate, Windows cannot verify the publisher.

### How to prevent it (for Developers)
To completely prevent this warning, the `.dll` file must be signed with a valid Code Signing Certificate from a trusted Certificate Authority (CA). If you are building your own application for distribution, it is recommended to sign all your binaries.

### How to bypass it (for Users)
If you trust the source of the DLL, you can manually "unblock" it:
1. Right-click on `php_winbinder.dll`.
2. Select **Properties**.
3. In the **General** tab, look for the **Security** section at the bottom.
4. Check the **Unblock** box and click **Apply** or **OK**.

Alternatively, when the warning appears, you can often click "More info" and then "Run anyway" (if applicable).
