# Registry Module

This module handles centralized type and descriptor management. It provides:

- Registration and resolution of dependencies between types
- Efficient descriptor lookup by name
- Centralized storage for all known types

## Module Status

- [x] TypeRegistry (test coverage: 97.73% lines of code) ✅
- [x] DescriptorPool

## Interactions with Other Modules

- **Descriptor**: for descriptor management
- **Dynamic**: for creating messages by type name
- **Service**: for type resolution during RPC calls
