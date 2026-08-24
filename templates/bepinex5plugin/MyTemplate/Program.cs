using System.Reflection;
using BepInEx;
using BepInEx.Logging;
using HarmonyLib;

namespace MyTemplate
{
	[BepInPlugin(MyPluginInfo.PLUGIN_GUID, MyPluginInfo.PLUGIN_NAME, MyPluginInfo.PLUGIN_VERSION)]
	internal class Plugin : BaseUnityPlugin
	{
		internal static Plugin Instance { get; private set; } = null!;
		internal Harmony HarmonyInstance = null!;
		internal new ManualLogSource Logger => base.Logger;

		internal Plugin()
		{
			Instance = this;
		}

		private void Awake()
		{
			this.Logger.LogInfo($"Plugin {MyPluginInfo.PLUGIN_GUID} is loaded!");
			this.HarmonyInstance = Harmony.CreateAndPatchAll(Assembly.GetExecutingAssembly());
		}

		private void OnDestroy()
		{
			this.Logger.LogInfo($"Plugin {MyPluginInfo.PLUGIN_GUID}'s OnDestroy() got called!");
			this.HarmonyInstance.UnpatchSelf();
		}
	}
}
