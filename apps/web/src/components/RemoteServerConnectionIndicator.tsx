import { useEffect, useMemo, useState, useSyncExternalStore } from "react";

import { Badge } from "./ui/badge";
import { Tooltip, TooltipPopup, TooltipTrigger } from "./ui/tooltip";
import { cn } from "~/lib/utils";
import { getWsConnectionSnapshot, onWsConnectionChange } from "~/wsNativeApi";
import { isElectron } from "~/env";

type RemoteConnectionPresentation = {
  dotClassName: string;
  label: string;
  tooltipLabel: string;
};

function wsToHttpOrigin(rawUrl: string | null): string | null {
  if (!rawUrl) return null;

  try {
    const url = new URL(rawUrl);
    if (url.protocol === "ws:") {
      url.protocol = "http:";
    } else if (url.protocol === "wss:") {
      url.protocol = "https:";
    }
    return url.origin;
  } catch {
    return null;
  }
}

function getConnectionPresentation(
  state: ReturnType<typeof getWsConnectionSnapshot>["state"],
): RemoteConnectionPresentation {
  switch (state) {
    case "open":
      return {
        dotClassName: "bg-emerald-500",
        label: "Remote connected",
        tooltipLabel: "Remote server connected",
      };
    case "reconnecting":
      return {
        dotClassName: "bg-amber-500",
        label: "Remote reconnecting",
        tooltipLabel: "Reconnecting to remote server",
      };
    case "connecting":
      return {
        dotClassName: "bg-sky-500",
        label: "Remote connecting",
        tooltipLabel: "Connecting to remote server",
      };
    case "closed":
      return {
        dotClassName: "bg-red-500",
        label: "Remote disconnected",
        tooltipLabel: "Remote server disconnected",
      };
    case "disposed":
      return {
        dotClassName: "bg-muted-foreground/35",
        label: "Remote offline",
        tooltipLabel: "Remote server offline",
      };
  }
}

export function RemoteServerConnectionIndicator({ className }: { className?: string }) {
  const snapshot = useSyncExternalStore(onWsConnectionChange, getWsConnectionSnapshot);
  const [remoteServerConfigured, setRemoteServerConfigured] = useState(false);

  useEffect(() => {
    if (!isElectron || !window.desktopBridge?.getRemoteServerConfig) {
      return;
    }

    let cancelled = false;
    void window.desktopBridge.getRemoteServerConfig().then((config) => {
      if (cancelled) return;
      setRemoteServerConfigured(Boolean(config.url));
    });

    return () => {
      cancelled = true;
    };
  }, []);

  const wsOrigin = useMemo(() => wsToHttpOrigin(snapshot.url), [snapshot.url]);
  const isRemoteConnection =
    remoteServerConfigured ||
    (!isElectron &&
      typeof window !== "undefined" &&
      wsOrigin !== null &&
      wsOrigin !== window.location.origin);

  if (!isRemoteConnection) {
    return null;
  }

  const presentation = getConnectionPresentation(snapshot.state);
  const targetLabel = snapshot.url
    ? (() => {
        try {
          return new URL(snapshot.url).host;
        } catch {
          return snapshot.url;
        }
      })()
    : "unknown host";

  return (
    <Tooltip>
      <TooltipTrigger
        render={
          <Badge
            variant="outline"
            size="sm"
            className={cn("max-w-full shrink-0 gap-1.5 text-muted-foreground", className)}
          >
            <span
              aria-hidden
              className={cn(
                "size-1.5 rounded-full shadow-[0_0_0_1px_var(--background)]",
                presentation.dotClassName,
              )}
            />
            <span className="truncate">{presentation.label}</span>
          </Badge>
        }
      />
      <TooltipPopup side="bottom">
        {presentation.tooltipLabel} {snapshot.url ? `(${targetLabel})` : ""}
      </TooltipPopup>
    </Tooltip>
  );
}
