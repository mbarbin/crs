# When to Use .crs-ignore Files

Generally, you want CRs to be found and tracked by the crs system - that's the whole point! Ignoring CRs prevents you from using the CRs workflow effectively.

> For technical details on file format, patterns, and commands, see [CRs Ignore Files Reference](../reference/crs-ignore-files/README.md).

However, there are legitimate cases where you need to ignore certain files. For example, in this very project, our `README.md` file contains illustrative CR comments to explain how the system works. Since we also use crs as an actual code review tool, we don't want these example CRs to be confused with real code review comments that need action.

As our project's `.crs-ignore` file explains: "The README.md file contains illustrative CRs which we ignore in code review... Ignoring CRs from the README prevents us from using the CRs workflow in this file. We've accepted this tradeoff."

## Common Use Cases

Other common use cases for `.crs-ignore` files might include:

- **Documentation or tutorial files** that demonstrate CR syntax
- **Vendor code or third-party libraries** that you don't control
- **Generated files** that shouldn't be part of code review
- **Test fixtures** that contain example CR comments for testing purposes
- **Legacy code** that you're not actively reviewing but contains old CR comments

## The Tradeoff

Remember that when you ignore CRs in a file, you're giving up the ability to use the CR workflow in that file. This means:

- You can't track pending code review items in those files
- You can't use CR commands to navigate review comments
- You lose the audit trail that CRs provide

Make sure this tradeoff is worth it for your specific use case.

## Best Practices

- **Be selective**: Only ignore files where CR comments would genuinely cause confusion
- **Document your reasoning**: Add comments in your `.crs-ignore` file explaining why certain patterns are ignored
- **Review regularly**: Periodically check if ignored patterns are still necessary
- **Use validation**: Run `crs tools crs-ignore validate` to catch unused patterns

What will you use `.crs-ignore` files for in your project?
