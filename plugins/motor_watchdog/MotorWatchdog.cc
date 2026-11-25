#include <array>
#include <chrono>
#include <cmath>
#include <mutex>
#include <string>

#include <gz/msgs/actuators.pb.h>
#include <gz/transport/Node.hh>
#include <gz/sim/System.hh>
#include <gz/plugin/Register.hh>

namespace laas
{

class MotorWatchdog :
    public gz::sim::System,
    public gz::sim::ISystemConfigure,
    public gz::sim::ISystemPreUpdate
{
public:
    void Configure(
        const gz::sim::Entity &,
        const std::shared_ptr<const sdf::Element> &,
        gz::sim::EntityComponentManager &,
        gz::sim::EventManager &) override
    {
        const std::string input =
            "/laas_quadplane/gazebo/command/motor_speed";

        const std::string output =
            "/laas_quadplane/gazebo/safe/motor_speed";

        this->publisher =
            this->node.Advertise<gz::msgs::Actuators>(output);

        this->node.Subscribe(
            input, &MotorWatchdog::OnCommand, this);
    }

    void PreUpdate(
        const gz::sim::UpdateInfo &,
        gz::sim::EntityComponentManager &) override
    {
        using namespace std::chrono;

        const auto now = steady_clock::now();

        if (now - this->lastPublish < milliseconds(20))
            return;

        this->lastPublish = now;

        std::array<double, 4> speeds{0, 0, 0, 0};

        {
            std::lock_guard<std::mutex> guard(this->mutex);

            if (this->valid &&
                now - this->lastCommand < milliseconds(500))
            {
                speeds = this->commands;
            }
        }

        gz::msgs::Actuators msg;

        for (const double speed : speeds)
            msg.add_velocity(speed);

        this->publisher.Publish(msg);
    }

private:
    void OnCommand(const gz::msgs::Actuators &_msg)
    {
        std::lock_guard<std::mutex> guard(this->mutex);

        this->valid = false;

        if (_msg.velocity_size() != 4)
            return;

        for (int i = 0; i < 4; ++i)
        {
            const double speed = _msg.velocity(i);

            if (!std::isfinite(speed) ||
                speed < 0.0 || speed > 800.0)
                return;
        }

        for (int i = 0; i < 4; ++i)
            this->commands[i] = _msg.velocity(i);

        this->lastCommand = std::chrono::steady_clock::now();
        this->valid = true;
    }

    gz::transport::Node node;
    gz::transport::Node::Publisher publisher;

    std::mutex mutex;
    std::array<double, 4> commands{0, 0, 0, 0};

    bool valid{false};

    std::chrono::steady_clock::time_point lastCommand{};
    std::chrono::steady_clock::time_point lastPublish{};
};

}

GZ_ADD_PLUGIN(
    laas::MotorWatchdog,
    gz::sim::System,
    laas::MotorWatchdog::ISystemConfigure,
    laas::MotorWatchdog::ISystemPreUpdate
)

GZ_ADD_PLUGIN_ALIAS(
    laas::MotorWatchdog,
    "laas::MotorWatchdog"
)
