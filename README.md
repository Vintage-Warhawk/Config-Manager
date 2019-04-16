# Config Manager

Garry's Mod In-game configuration manager

## Getting Started

How to register, set, and get configuration options.

### Registering your configuration option.

You can run this code in CLIENT for user configuration, or run it in SERVER for admin configuration.
The available datatypes are "string", "number", "boolean"

```
CFGM:Register( name, datatype, fallback, description )
```

### Managing your configuration option.

To set and get configuration make sure you are running the code in the same realm it was registered in.

```
CFGM:Set( name, value )
```



```
CFGM:Get( name )
```
## The UI
This module has a in-game menu you can access.

### Command
In console type the following to open the menu.

```
ConfigManager
```
WIP but functional.
![](https://i.ibb.co/fXGpzCM/a9bdd2afe6d0f00ee8fc39a0c71a83b2.png)
