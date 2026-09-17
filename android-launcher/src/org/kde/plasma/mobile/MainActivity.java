package org.kde.plasma.mobile;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.os.BatteryManager;
import android.os.Bundle;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.GridLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Locale;

public class MainActivity extends Activity {

    // NativOS / Plasma 6 Palette
    private final int COLOR_BG_TOP = Color.parseColor("#12192B");
    private final int COLOR_BG_BOTTOM = Color.parseColor("#090B12");
    private final int COLOR_DOCK = Color.parseColor("#200E121E");
    private final int COLOR_ICON_BG = Color.parseColor("#1B2234");
    private final int COLOR_BORDER = Color.parseColor("#2E3852");
    private final int COLOR_ACCENT = Color.parseColor("#3DAEE9");
    private final int COLOR_TEXT = Color.parseColor("#FFFFFF");
    private final int COLOR_MUTED = Color.parseColor("#A0A5AD");

    private TextView clockView;
    private TextView dateView;
    private TextView searchBar;
    private FrameLayout appDrawerOverlay;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);

        FrameLayout rootContainer = new FrameLayout(this);

        // Wallpaper gradient
        GradientDrawable wallpaper = new GradientDrawable(
            GradientDrawable.Orientation.TOP_BOTTOM,
            new int[]{COLOR_BG_TOP, Color.parseColor("#0E1422"), COLOR_BG_BOTTOM}
        );
        rootContainer.setBackground(wallpaper);

        // Main Phone Homescreen Layout
        LinearLayout homescreen = new LinearLayout(this);
        homescreen.setOrientation(LinearLayout.VERTICAL);
        homescreen.setLayoutParams(new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        homescreen.setPadding(dp(20), dp(36), dp(20), dp(16));

        // 1. Top Status Header (Time, Date, Status pill)
        LinearLayout topHeader = new LinearLayout(this);
        topHeader.setOrientation(LinearLayout.VERTICAL);
        topHeader.setGravity(Gravity.CENTER);

        clockView = new TextView(this);
        clockView.setText(new SimpleDateFormat("HH:mm", Locale.getDefault()).format(new Date()));
        clockView.setTextSize(58);
        clockView.setTypeface(Typeface.create("sans-serif-light", Typeface.NORMAL));
        clockView.setTextColor(COLOR_TEXT);
        clockView.setGravity(Gravity.CENTER);
        topHeader.addView(clockView);

        dateView = new TextView(this);
        dateView.setText(new SimpleDateFormat("EEEE, MMMM d", Locale.getDefault()).format(new Date()));
        dateView.setTextSize(15);
        dateView.setTypeface(Typeface.create("sans-serif-medium", Typeface.NORMAL));
        dateView.setTextColor(COLOR_ACCENT);
        dateView.setGravity(Gravity.CENTER);
        dateView.setPadding(0, 0, 0, dp(6));
        topHeader.addView(dateView);

        // Status pill (Cores & Battery)
        TextView pill = new TextView(this);
        pill.setText("8 Cores Online • Nexus 6P • Arch Linux ARM64");
        pill.setTextSize(11);
        pill.setTextColor(Color.parseColor("#80D6FF"));
        pill.setPadding(dp(12), dp(4), dp(12), dp(4));
        GradientDrawable pillBg = new GradientDrawable();
        pillBg.setColor(Color.parseColor("#263DAEE9"));
        pillBg.setCornerRadius(dp(12));
        pill.setBackground(pillBg);
        pill.setGravity(Gravity.CENTER);
        topHeader.addView(pill);

        homescreen.addView(topHeader);

        // Spacer to push apps to natural phone reach
        View verticalSpacer = new View(this);
        verticalSpacer.setLayoutParams(new LinearLayout.LayoutParams(1, 0, 1.0f));
        homescreen.addView(verticalSpacer);

        // 2. Search / Quick Launch Pill (Google / Terminal Bar)
        searchBar = new TextView(this);
        searchBar.setText("🔍 Search apps or terminal...");
        searchBar.setTextSize(14);
        searchBar.setTextColor(COLOR_MUTED);
        searchBar.setPadding(dp(16), dp(12), dp(16), dp(12));
        GradientDrawable searchBg = new GradientDrawable();
        searchBg.setColor(Color.parseColor("#80141824"));
        searchBg.setCornerRadius(dp(22));
        searchBg.setStroke(dp(1), COLOR_BORDER);
        searchBar.setBackground(searchBg);
        searchBar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                toggleAppDrawer(true);
            }
        });
        homescreen.addView(searchBar);
        homescreen.addView(createSpacer(20));

        // 3. Homescreen Grid (4x2 Favorite App Icons)
        GridLayout homeGrid = new GridLayout(this);
        homeGrid.setColumnCount(4);
        homeGrid.setRowCount(2);
        homeGrid.setAlignmentMode(GridLayout.ALIGN_BOUNDS);
        homeGrid.setUseDefaultMargins(false);

        String[][] homeApps = {
            {"📞", "Phone", "android.intent.action.DIAL", "#2ECC71"},
            {"💬", "Messages", "android.intent.action.MAIN", "#3498DB", "vnd.android-dir/mms-sms"},
            {"🌐", "Browser", "https://plasma-mobile.org", "#27AE60"},
            {"📷", "Camera", "android.media.action.IMAGE_CAPTURE", "#E67E22"},
            {"⚙", "Settings", "android.settings.SETTINGS", "#7F8C8D"},
            {"⏰", "Clock", "android.intent.action.SHOW_ALARMS", "#F39C12"},
            {"📁", "Files", "android.intent.action.OPEN_DOCUMENT", "#1D99F3"},
            {"🚀", "Linux Shell", "RUN_PLASMA", "#756BFF"}
        };

        int cellWidth = (getResources().getDisplayMetrics().widthPixels - dp(40)) / 4;

        for (final String[] app : homeApps) {
            LinearLayout cell = createPhoneAppIcon(app[0], app[1], app[3], cellWidth);
            cell.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    handleAppLaunch(app);
                }
            });
            homeGrid.addView(cell);
        }

        homescreen.addView(homeGrid);
        homescreen.addView(createSpacer(18));

        // 4. Phone Dock Bar (Bottom 4 Icons with translucent dock plate)
        LinearLayout dockContainer = new LinearLayout(this);
        dockContainer.setOrientation(LinearLayout.HORIZONTAL);
        dockContainer.setGravity(Gravity.CENTER);
        dockContainer.setPadding(dp(8), dp(10), dp(8), dp(10));
        GradientDrawable dockBg = new GradientDrawable();
        dockBg.setColor(Color.parseColor("#4D121724"));
        dockBg.setCornerRadius(dp(28));
        dockBg.setStroke(dp(1), Color.parseColor("#33FFFFFF"));
        dockContainer.setBackground(dockBg);

        String[][] dockApps = {
            {"📞", "Call", "android.intent.action.DIAL", "#2ECC71"},
            {"💬", "Chat", "android.intent.action.MAIN", "#3498DB", "vnd.android-dir/mms-sms"},
            {"📷", "Snap", "android.media.action.IMAGE_CAPTURE", "#E67E22"},
            {"▦", "Apps", "TOGGLE_DRAWER", "#756BFF"}
        };

        int dockCellWidth = (getResources().getDisplayMetrics().widthPixels - dp(64)) / 4;
        for (final String[] dApp : dockApps) {
            LinearLayout dCell = createPhoneAppIcon(dApp[0], dApp[1], dApp[3], dockCellWidth);
            dCell.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    if ("TOGGLE_DRAWER".equals(dApp[2])) {
                        toggleAppDrawer(true);
                    } else {
                        handleAppLaunch(dApp);
                    }
                }
            });
            dockContainer.addView(dCell);
        }

        homescreen.addView(dockContainer);
        rootContainer.addView(homescreen);

        // 5. Full App Drawer (Slide-over)
        appDrawerOverlay = createAppDrawer();
        appDrawerOverlay.setVisibility(View.GONE);
        rootContainer.addView(appDrawerOverlay);

        setContentView(rootContainer);
    }

    private LinearLayout createPhoneAppIcon(String icon, String label, String colorHex, int width) {
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setGravity(Gravity.CENTER_HORIZONTAL);
        layout.setLayoutParams(new LinearLayout.LayoutParams(width, ViewGroup.LayoutParams.WRAP_CONTENT));
        layout.setPadding(dp(4), dp(6), dp(4), dp(6));

        // Rounded Squircle Icon (Modern phone launcher style)
        FrameLayout squircle = new FrameLayout(this);
        LinearLayout.LayoutParams iconParams = new LinearLayout.LayoutParams(dp(54), dp(54));
        squircle.setLayoutParams(iconParams);

        GradientDrawable iconBg = new GradientDrawable();
        iconBg.setColor(Color.parseColor(colorHex));
        iconBg.setCornerRadius(dp(18));
        squircle.setBackground(iconBg);

        TextView iconText = new TextView(this);
        iconText.setText(icon);
        iconText.setTextSize(24);
        iconText.setTextColor(Color.WHITE);
        iconText.setGravity(Gravity.CENTER);
        FrameLayout.LayoutParams textParams = new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
        iconText.setLayoutParams(textParams);
        squircle.addView(iconText);

        layout.addView(squircle);

        // Icon Label
        TextView labelView = new TextView(this);
        labelView.setText(label);
        labelView.setTextSize(11);
        labelView.setTextColor(COLOR_TEXT);
        labelView.setGravity(Gravity.CENTER);
        labelView.setPadding(0, dp(4), 0, 0);
        labelView.setSingleLine(true);
        layout.addView(labelView);

        return layout;
    }

    private FrameLayout createAppDrawer() {
        FrameLayout drawer = new FrameLayout(this);
        drawer.setLayoutParams(new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        drawer.setBackgroundColor(Color.parseColor("#F2090B12"));

        LinearLayout content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        content.setPadding(dp(20), dp(44), dp(20), dp(20));

        // Drawer Header
        LinearLayout dHeader = new LinearLayout(this);
        dHeader.setOrientation(LinearLayout.HORIZONTAL);
        dHeader.setGravity(Gravity.CENTER_VERTICAL);

        TextView dTitle = new TextView(this);
        dTitle.setText("All Applications");
        dTitle.setTextSize(20);
        dTitle.setTypeface(Typeface.DEFAULT_BOLD);
        dTitle.setTextColor(COLOR_TEXT);
        dTitle.setLayoutParams(new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1.0f));
        dHeader.addView(dTitle);

        TextView closeBtn = new TextView(this);
        closeBtn.setText("✕");
        closeBtn.setTextSize(22);
        closeBtn.setTextColor(COLOR_MUTED);
        closeBtn.setPadding(dp(12), dp(8), dp(12), dp(8));
        closeBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                toggleAppDrawer(false);
            }
        });
        dHeader.addView(closeBtn);

        content.addView(dHeader);
        content.addView(createSpacer(16));

        // Drawer Grid
        ScrollView scroll = new ScrollView(this);
        GridLayout grid = new GridLayout(this);
        grid.setColumnCount(4);
        int cellWidth = (getResources().getDisplayMetrics().widthPixels - dp(40)) / 4;

        String[][] allApps = {
            {"📞", "Phone", "android.intent.action.DIAL", "#2ECC71"},
            {"💬", "Messages", "android.intent.action.MAIN", "#3498DB", "vnd.android-dir/mms-sms"},
            {"🌐", "Browser", "https://plasma-mobile.org", "#27AE60"},
            {"📷", "Camera", "android.media.action.IMAGE_CAPTURE", "#E67E22"},
            {"⚙", "Settings", "android.settings.SETTINGS", "#7F8C8D"},
            {"⏰", "Clock", "android.intent.action.SHOW_ALARMS", "#F39C12"},
            {"📁", "Files", "android.intent.action.OPEN_DOCUMENT", "#1D99F3"},
            {"✉", "Mail", "android.intent.action.MAIN", "#C0392B"},
            {"📝", "Notes", "android.intent.action.CREATE_NOTE", "#8E44AD"},
            {"🧮", "Calc", "android.intent.action.MAIN", "#E74C3C"},
            {"⛅", "Weather", "https://wttr.in", "#3498DB"},
            {"🚀", "Plasma Shell", "RUN_PLASMA", "#756BFF"}
        };

        for (final String[] a : allApps) {
            LinearLayout cell = createPhoneAppIcon(a[0], a[1], a[3], cellWidth);
            cell.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    toggleAppDrawer(false);
                    handleAppLaunch(a);
                }
            });
            grid.addView(cell);
        }

        scroll.addView(grid);
        content.addView(scroll);
        drawer.addView(content);
        return drawer;
    }

    private void toggleAppDrawer(boolean show) {
        if (appDrawerOverlay != null) {
            appDrawerOverlay.setVisibility(show ? View.VISIBLE : View.GONE);
        }
    }

    private void handleAppLaunch(String[] app) {
        try {
            if ("RUN_PLASMA".equals(app[2])) {
                Runtime.getRuntime().exec(new String[]{"/system/bin/sh", "-c", "/data/enter-plasma.sh"});
                Toast.makeText(this, "Launching Linux Plasma Session...", Toast.LENGTH_SHORT).show();
            } else if (app.length > 4) {
                Intent intent = new Intent(app[2]);
                intent.setType(app[4]);
                startActivity(intent);
            } else if (app[2].startsWith("http")) {
                Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(app[2]));
                startActivity(browserIntent);
            } else {
                Intent intent = new Intent(app[2]);
                startActivity(intent);
            }
        } catch (Exception e) {
            Toast.makeText(this, "Starting " + app[1], Toast.LENGTH_SHORT).show();
        }
    }

    private View createSpacer(int heightDp) {
        View v = new View(this);
        v.setLayoutParams(new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(heightDp)));
        return v;
    }

    private int dp(int value) {
        return (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, getResources().getDisplayMetrics());
    }

    @Override
    public void onBackPressed() {
        if (appDrawerOverlay != null && appDrawerOverlay.getVisibility() == View.VISIBLE) {
            toggleAppDrawer(false);
        }
    }
}
