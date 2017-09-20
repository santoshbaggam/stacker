Things get way more complicated for developers when it comes to pushing their apps live to the web!

Stacker makes whipping up web servers a cinch, letting developers focus on code.

### Installation

``` curl
curl -sSL https://raw.githubusercontent.com/santoshbaggam/stacker/master/install.sh | bash
```

### Build

Once installed, simply run `stacker build` to install the latest stack of your choice.

> As of now, Stacker provides only the latest PHP build stack. I will be working more on adding the other stacks soon.

### Usage

In order to map a new site, say example.com (or) ex.example.com, run `stacker site` and follow the prompts to seamlessly map your domains/sub-domains to your application.

Make sure to provide the publicly serving folder to serve the application.
