# Config Manager

Garry's Mod In-game configuration manager

## Getting Started

How to register, set, and get configuration options.

### Registering your configuration option.

You can run this code in CLIENT for user configuration, or run it in SERVER for admin configuration.

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
![](https://ibb.co/r0RhW5X)
