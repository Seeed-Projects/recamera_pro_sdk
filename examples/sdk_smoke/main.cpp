#include <gst/gst.h>
#include <opencv2/core.hpp>
#include <opencv2/imgproc.hpp>
#include <rknn_api.h>

#include <iostream>
#include <string>

namespace {

bool check_opencv() {
    const cv::Mat bgr(8, 8, CV_8UC3, cv::Scalar(10, 20, 30));
    cv::Mat gray;
    cv::cvtColor(bgr, gray, cv::COLOR_BGR2GRAY);
    const bool ok = gray.rows == 8 && gray.cols == 8 && gray.type() == CV_8UC1;
    std::cout << "OpenCV " << CV_VERSION << ": " << (ok ? "OK" : "FAILED") << '\n';
    return ok;
}

bool check_gstreamer() {
    GError* error = nullptr;
    GstElement* pipeline = gst_parse_launch(
        "fakesrc num-buffers=1 ! fakesink sync=false", &error);
    if (pipeline == nullptr) {
        std::cerr << "GStreamer pipeline creation failed: "
                  << (error != nullptr ? error->message : "unknown error") << '\n';
        g_clear_error(&error);
        return false;
    }

    const GstStateChangeReturn state_result =
        gst_element_set_state(pipeline, GST_STATE_PLAYING);
    bool ok = state_result != GST_STATE_CHANGE_FAILURE;
    if (ok) {
        GstBus* bus = gst_element_get_bus(pipeline);
        GstMessage* message = gst_bus_timed_pop_filtered(
            bus, 5 * GST_SECOND,
            static_cast<GstMessageType>(GST_MESSAGE_EOS | GST_MESSAGE_ERROR));
        ok = message != nullptr && GST_MESSAGE_TYPE(message) == GST_MESSAGE_EOS;
        if (message != nullptr) {
            gst_message_unref(message);
        }
        gst_object_unref(bus);
    }

    gst_element_set_state(pipeline, GST_STATE_NULL);
    gst_object_unref(pipeline);
    std::cout << "GStreamer " << gst_version_string() << ": "
              << (ok ? "OK" : "FAILED") << '\n';
    return ok;
}

void check_rknn_loader() {
    rknn_sdk_version version{};
    const int result = rknn_query(0, RKNN_QUERY_SDK_VERSION, &version, sizeof(version));
    std::cout << "RKNN Runtime library: loaded (invalid-context probe returned "
              << result << ")\n";
}

}  // namespace

int main(int argc, char** argv) {
    gst_init(&argc, &argv);

    std::cout << "reCamera Pro SDK smoke test\n";
    const bool opencv_ok = check_opencv();
    const bool gstreamer_ok = check_gstreamer();
    check_rknn_loader();

    const bool ok = opencv_ok && gstreamer_ok;
    std::cout << (ok ? "ALL CHECKS PASSED" : "CHECK FAILED") << '\n';
    return ok ? 0 : 1;
}
