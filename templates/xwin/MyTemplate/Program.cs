using System.Runtime.InteropServices;

namespace Workspace;

internal static partial class Program
{
	[LibraryImport("user32.dll", StringMarshalling = StringMarshalling.Utf16)]
	private static partial int MessageBoxW(IntPtr hWnd, string lpText, string lpCaption, uint uType);

	[LibraryImport("kernel32.dll")]
	[return: MarshalAs(UnmanagedType.Bool)]
	private static partial bool Beep(uint dwFreq, uint dwDuration);

	internal static void Main(string[] args)
	{
		Console.WriteLine("Hello, World!");
		Console.WriteLine($"Args: {(args.Length == 0 ? "(null)" : string.Join(" ", args))}");

		const uint MB_OK = 0x00000000;
		const uint MB_ICONINFORMATION = 0x00000040;

		Beep(750, 400);

		var result = MessageBoxW(
			IntPtr.Zero,
			"Hello world",
			"NativeAOT Crossbuild",
			MB_OK | MB_ICONINFORMATION
		);

		Console.WriteLine($"Result: {result}");
	}
}
