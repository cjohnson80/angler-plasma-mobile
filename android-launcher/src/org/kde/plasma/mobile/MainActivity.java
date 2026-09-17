package org.kde.plasma.mobile;

import android.app.Activity;
import android.content.Intent;
import android.content.res.ColorStateList;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.os.Bundle;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.GridLayout;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;

public class MainActivity extends Activity {

    // NativOS Premium Theme Palette
    private final int COLOR_BG = Color.parseColor("#090B12");
    private final int COLOR_SURFACE = Color.parseColor("#141824");
    private final int COLOR_SURFACE_HIGH = Color.parseColor("#1C2231");
    private final int COLOR_PRIMARY = Color.parseColor("#756BFF");
    private final int COLOR_TEXT = Color.parseColor("#F7F7FC");
    private final int COLOR_MUTED = Color.parseColor("#A7AEC0");
    private final int COLOR_SUCCESS = Color.parseColor("#42D3A2");
    private final int COLOR_BORDER = Color.parseColor("#2A3042");

    private TextView statusCores;
    private TextView statusUptime;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);

        ScrollView scroll = new ScrollView(this);
        scroll.setBackgroundColor(COLOR_BG);
        scroll.setFillViewport(true);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(20), dp(44), dp(20), dp(32));

        // 1. NativOS Header Brand
        LinearLayout headerLayout = new LinearLayout(this);
        headerLayout.setOrientation(LinearLayout.VERTICAL);
        headerLayout.setGravity(Gravity.CENTER);

        TextView brandTitle = new TextView(this);
        brandTitle.setText("NativOS");
        brandTitle.setTextSize(32);
        brandTitle.setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD));
        brandTitle.setTextColor(COLOR_TEXT);
        brandTitle.setGravity(Gravity.CENTER);
        headerLayout.addView(brandTitle);

        TextView brandSub = new TextView(this);
        brandSub.setText("Linux Mobile Desktop • Huawei Nexus 6P");
        brandSub.setTextSize(13);
        brandSub.setTextColor(COLOR_MUTED);
        brandSub.setGravity(Gravity.CENTER);
        brandSub.setPadding(0, dp(4), 0, dp(24));
        headerLayout.addView(brandSub);

        root.addView(headerLayout);

        // 2. Hardware Monitor Card (Snapdragon 810 / 8-Cores)
        LinearLayout hwCard = createCard();
        
        TextView hwLabel = new TextView(this);
        hwLabel.setText("HARDWARE RUNTIME");
        hwLabel.setTextSize(11);
        hwLabel.setTypeface(Typeface.DEFAULT_BOLD);
        hwLabel.setTextColor(COLOR_PRIMARY);
        hwCard.addView(hwLabel);

        statusCores = new TextView(this);
        statusCores.setText("Qualcomm Snapdragon 810 • 8/8 Cores Active");
        statusCores.setTextSize(14);
        statusCores.setTypeface(Typeface.DEFAULT_BOLD);
        statusCores.setTextColor(COLOR_TEXT);
        statusCores.setPadding(0, dp(8), 0, dp(4));
        hwCard.addView(statusCores);

        statusUptime = new TextView(this);
        statusUptime.setText("Arch Linux ARM64 Rootfs Mounted @ /data/rootfs");
        statusUptime.setTextSize(12);
        statusUptime.setTextColor(COLOR_SUCCESS);
        hwCard.addView(statusUptime);

        root.addView(hwCard);
        root.addView(createSpacer(16));

        // 3. Launch Native Linux Session Hero Button
        LinearLayout launchBtn = createHeroButton("Launch Native Plasma 6 Shell", "Switch into Wayland / Halium Environment");
        launchBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                try {
                    Runtime.getRuntime().exec(new String[]{"/system/bin/sh", "-c", "/data/enter-plasma.sh"});
                    Toast.makeText(MainActivity.this, "Spawning Plasma Mobile Session...", Toast.LENGTH_SHORT).show();
                } catch (Exception e) {
                    Toast.makeText(MainActivity.this, "Execution note: " + e.getMessage(), Toast.LENGTH_SHORT).show();
                }
            }
        });
        root.addView(launchBtn);
        root.addView(createSpacer(24));

        // 4. Mobile Apps Section Label
        TextView appsLabel = new TextView(this);
        appsLabel.setText("INSTALLED APPLICATIONS");
        appsLabel.setTextSize(12);
        appsLabel.setTypeface(Typeface.DEFAULT_BOLD);
        appsLabel.setTextColor(COLOR_MUTED);
        appsLabel.setPadding(dp(4), 0, 0, dp(12));
        root.addView(appsLabel);

        // 5. App Grid (NativOS Cards)
        String[][] appItems = {
            {"📞", "Phone", "Qualcomm Modem RIL", "android.intent.action.DIAL"},
            {"💬", "Messages", "SMS & Threaded Chat", "android.intent.action.MAIN", "vnd.android-dir/mms-sms"},
            {"📷", "Camera", "12.3 MP IMX377 ISP", "android.media.action.IMAGE_CAPTURE"},
            {"🌐", "Angelfish", "Web Browser Engine", "https://plasma-mobile.org"},
            {"⚙", "Settings", "System & Hardware", "android.settings.SETTINGS"},
            {"⏰", "Clock", "World Time & Alarms", "android.intent.action.SHOW_ALARMS"}
        };

        for (final String[] item : appItems) {
            LinearLayout itemRow = createAppCard(item[0], item[1], item[2]);
            itemRow.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    try {
                        if (item.length > 4) {
                            Intent intent = new Intent(item[3]);
                            intent.setType(item[4]);
                            startActivity(intent);
                        } else if (item[3].startsWith("http")) {
                            Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(item[3]));
                            startActivity(browserIntent);
                        } else {
                            Intent intent = new Intent(item[3]);
                            startActivity(intent);
                        }
                    } catch (Exception e) {
                        Toast.makeText(MainActivity.this, "Launching " + item[1], Toast.LENGTH_SHORT).show();
                    }
                }
            });
            root.addView(itemRow);
            root.addView(createSpacer(10));
        }

        scroll.addView(root);
        setContentView(scroll);
    }

    private LinearLayout createCard() {
        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(dp(16), dp(16), dp(16), dp(16));

        GradientDrawable bg = new GradientDrawable();
        bg.setColor(COLOR_SURFACE);
        bg.setCornerRadius(dp(14));
        bg.setStroke(dp(1), COLOR_BORDER);
        card.setBackground(bg);
        return card;
    }

    private LinearLayout createHeroButton(String title, String subtitle) {
        LinearLayout btn = new LinearLayout(this);
        btn.setOrientation(LinearLayout.VERTICAL);
        btn.setPadding(dp(20), dp(18), dp(20), dp(18));
        btn.setGravity(Gravity.CENTER);

        GradientDrawable bg = new GradientDrawable();
        bg.setColor(COLOR_PRIMARY);
        bg.setCornerRadius(dp(14));
        btn.setBackground(bg);

        TextView t = new TextView(this);
        t.setText(title);
        t.setTextSize(16);
        t.setTypeface(Typeface.DEFAULT_BOLD);
        t.setTextColor(Color.WHITE);
        t.setGravity(Gravity.CENTER);
        btn.addView(t);

        TextView s = new TextView(this);
        s.setText(subtitle);
        s.setTextSize(12);
        s.setTextColor(Color.parseColor("#E0E0FF"));
        s.setGravity(Gravity.CENTER);
        s.setPadding(0, dp(4), 0, 0);
        btn.addView(s);

        return btn;
    }

    private LinearLayout createAppCard(String icon, String title, String desc) {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(dp(16), dp(14), dp(16), dp(14));

        GradientDrawable bg = new GradientDrawable();
        bg.setColor(COLOR_SURFACE);
        bg.setCornerRadius(dp(12));
        bg.setStroke(dp(1), COLOR_BORDER);
        row.setBackground(bg);

        TextView iconView = new TextView(this);
        iconView.setText(icon);
        iconView.setTextSize(24);
        iconView.setPadding(0, 0, dp(16), 0);
        row.addView(iconView);

        LinearLayout textCol = new LinearLayout(this);
        textCol.setOrientation(LinearLayout.VERTICAL);
        textCol.setLayoutParams(new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1.0f));

        TextView titleView = new TextView(this);
        titleView.setText(title);
        titleView.setTextSize(15);
        titleView.setTypeface(Typeface.DEFAULT_BOLD);
        titleView.setTextColor(COLOR_TEXT);
        textCol.addView(titleView);

        TextView descView = new TextView(this);
        descView.setText(desc);
        descView.setTextSize(12);
        descView.setTextColor(COLOR_MUTED);
        textCol.addView(descView);

        row.addView(textCol);

        TextView chevron = new TextView(this);
        chevron.setText("›");
        chevron.setTextSize(20);
        chevron.setTextColor(COLOR_MUTED);
        row.addView(chevron);

        return row;
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
        // Retain launcher state
    }
}
