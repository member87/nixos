import app from "ags/gtk4/app";
import { Astal, Gtk } from "ags/gtk4";
import { createBinding } from "ags";
import Battery from "gi://AstalBattery";
import { SystemNetwork } from "./system/Network";
import { SystemBluetooth } from "./system/Bluetooth";
let panelWindow: Astal.Window | null = null;

function WifiBluetoothSection() {
  return (
    <box cssClasses={["panel-section"]} orientation={Gtk.Orientation.VERTICAL} spacing={4}>
      <box spacing={8}>

        <SystemNetwork />
        <SystemBluetooth />
      </box>
    </box>
  );
}

function BatterySection() {
  const battery = Battery.get_default();

  return (
    <box cssClasses={["panel-section"]} orientation={Gtk.Orientation.VERTICAL} spacing={4}>
      <box spacing={8}>
        <image iconName={createBinding(battery, "iconName")} />
        <label label={createBinding(battery, "percentage").as(p => `${Math.round(p * 100)}%`)} />
      </box>
    </box>
  );
}

export function createSimplePanel() {
  const { TOP, RIGHT } = Astal.WindowAnchor;

  if (panelWindow) {
    return panelWindow;
  }

  panelWindow = (
    <window
      visible={false}
      name="simple-panel"
      anchor={TOP | RIGHT}
      exclusivity={Astal.Exclusivity.NORMAL}
      application={app}
    >
      <box cssClasses={["simple-panel"]} orientation={Gtk.Orientation.VERTICAL} spacing={12}>
        <BatterySection />
        <WifiBluetoothSection />
      </box>
    </window>
  ) as Astal.Window;

  return panelWindow;
}

export function useSimplePanel() {
  return {
    toggle: () => {
      if (!panelWindow) {
        panelWindow = createSimplePanel();
      }
      const isVisible = panelWindow.get_visible();
      panelWindow.set_visible(!isVisible);
    },
    show: () => {
      if (!panelWindow) {
        panelWindow = createSimplePanel();
      }
      panelWindow.set_visible(true);
    },
    hide: () => {
      if (panelWindow) {
        panelWindow.set_visible(false);
      }
    }
  };
}
