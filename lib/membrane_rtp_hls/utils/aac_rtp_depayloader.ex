defmodule MembraneRtpHls.Utils.AacRtpDepayloader do
  use Membrane.Filter
  alias Membrane.Buffer
  alias Membrane.AAC

  def_input_pad :input, demand_unit: :buffers, caps: :any
  def_output_pad :output, caps: {AAC, encapsulation: :none}

  def_options profile: [
                default: :LC
              ],
              sample_rate: [
                default: 44100
              ],
              channels: [
                default: 2
              ]

  @impl true
  def handle_init(options) do
    {:ok, options |> Map.merge(%{leftover: <<>>})}
  end

  @impl true
  def handle_demand(:output, size, :buffers, _ctx, state) do
    {{:ok, demand: {:input, size}}, state}
  end

  @impl true
  def handle_prepared_to_playing(_ctx, state) do
    caps = %AAC{profile: state.profile, sample_rate: state.sample_rate, channels: state.channels}
    {{:ok, caps: {:output, caps}}, state}
  end

  @impl true
  def handle_process(:input, buffer, _ctx, state) do
    with {:ok, payload} <- parse_packet(buffer.payload) do
      {{:ok, buffer: {:output, %Buffer{buffer | payload: payload}}}, state}
    else
      {:error, reason} -> {{:error, reason}, state}
    end
  end

  @impl true
  def handle_caps(:input, caps, _ctx, state) do
    caps = %AAC{profile: state.profile, sample_rate: state.sample_rate, channels: state.channels}
    {{:ok, caps: {:output, caps}}, state}
  end

  defp parse_packet(packet) do
    headers_length = 16

    with <<^headers_length::16, au_size::13, _au_index::3, au::binary-size(au_size)>> <-
           packet do
      {:ok, au}
    else
      _ -> {:error, :invalid_packet}
    end
  end
end
