# removes what base-dinit installed apart from the /usr/local/bin tools (hdx removes those)
rm -f /sbin/dinit-init
rm -rf /etc/dinit.d /etc/dinit
rm -f /usr/local/sbin/dinit-shutdown /usr/local/sbin/dinit-poweroff /usr/local/sbin/dinit-reboot \
      /usr/local/sbin/dinit-halt /usr/local/sbin/dinit-soft-reboot
rm -f /usr/local/share/man/man5/dinit-service.5 /usr/local/share/man/man8/dinit.8 \
      /usr/local/share/man/man8/dinitctl.8 /usr/local/share/man/man8/dinit-check.8 \
      /usr/local/share/man/man8/dinit-monitor.8 /usr/local/share/man/man8/dinit-shutdown.8 \
      /usr/local/share/man/man8/dinit-poweroff.8 /usr/local/share/man/man8/dinit-reboot.8 \
      /usr/local/share/man/man8/dinit-halt.8 /usr/local/share/man/man8/dinit-soft-reboot.8
echo "note: make sure no limine entry still boots with init=/sbin/dinit-init"
