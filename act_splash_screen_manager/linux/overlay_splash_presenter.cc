// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

#include "overlay_splash_presenter.h"

#include <utility>

namespace act_splash_screen
{
    namespace
    {

        /// Bit position of the red channel in a 0xRRGGBB colour.
        constexpr unsigned int kRedShift = 16;
        /// Bit position of the green channel in a 0xRRGGBB colour.
        constexpr unsigned int kGreenShift = 8;
        /// Mask keeping the low byte of a colour channel.
        constexpr unsigned int kChannelMask = 0xFF;
        /// Largest value of a colour channel, used to bring it into the 0..1 range Cairo wants.
        constexpr double kChannelMax = 255.0;

        /// @brief Draws the splash screen, called by GTK whenever the area has to be repainted.
        gboolean OnDraw(GtkWidget *area, cairo_t *cr, gpointer user_data)
        {
            static_cast<OverlaySplashPresenter *>(user_data)->draw(area, cr);

            return TRUE;
        }

    } // namespace

    OverlaySplashPresenter::OverlaySplashPresenter(SplashConfig config, GdkPixbuf *image)
        : m_config(std::move(config)),
          m_image(image)
    {
    }

    OverlaySplashPresenter::~OverlaySplashPresenter()
    {
        g_clear_object(&m_image);
    }

    GtkWidget *OverlaySplashPresenter::attach(GtkWindow *window)
    {
        GtkOverlay *overlay = GTK_OVERLAY(gtk_overlay_new());
        gtk_widget_show(GTK_WIDGET(overlay));
        gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(overlay));

        m_area = gtk_drawing_area_new();
        gtk_widget_set_halign(m_area, GTK_ALIGN_FILL);
        gtk_widget_set_valign(m_area, GTK_ALIGN_FILL);
        g_signal_connect(m_area, "draw", G_CALLBACK(OnDraw), this);
        gtk_widget_show(m_area);
        gtk_overlay_add_overlay(overlay, m_area);

        return GTK_WIDGET(overlay);
    }

    void OverlaySplashPresenter::hide()
    {
        if (m_area == nullptr)
        {
            return;
        }

        gtk_widget_destroy(m_area);
        m_area = nullptr;
    }

    void OverlaySplashPresenter::draw(GtkWidget *area, cairo_t *cr) const
    {
        const double area_width = gtk_widget_get_allocated_width(area);
        const double area_height = gtk_widget_get_allocated_height(area);
        const double image_width = gdk_pixbuf_get_width(m_image);
        const double image_height = gdk_pixbuf_get_height(m_image);

        cairo_set_source_rgb(cr,
                             ((m_config.backgroundColor >> kRedShift) & kChannelMask) / kChannelMax,
                             ((m_config.backgroundColor >> kGreenShift) & kChannelMask) /
                                 kChannelMax,
                             (m_config.backgroundColor & kChannelMask) / kChannelMax);
        cairo_paint(cr);

        const double horizontal_scale = area_width / image_width;
        const double vertical_scale = area_height / image_height;
        const double scale = m_config.fit == SplashFit::COVER
                                 ? MAX(horizontal_scale, vertical_scale)
                                 : MIN(horizontal_scale, vertical_scale);

        cairo_scale(cr, scale, scale);
        gdk_cairo_set_source_pixbuf(cr,
                                    m_image,
                                    (area_width / scale - image_width) / 2,
                                    (area_height / scale - image_height) / 2);
        cairo_paint(cr);
    }

} // namespace act_splash_screen
