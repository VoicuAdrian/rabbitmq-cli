## The contents of this file are subject to the Mozilla Public License
## Version 1.1 (the "License"); you may not use this file except in
## compliance with the License. You may obtain a copy of the License
## at http://www.mozilla.org/MPL/
##
## Software distributed under the License is distributed on an "AS IS"
## basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
## the License for the specific language governing rights and
## limitations under the License.
##
## The Original Code is RabbitMQ.
##
## The Initial Developer of the Original Code is GoPivotal, Inc.
## Copyright (c) 2007-2019 Pivotal Software, Inc.  All rights reserved.

alias RabbitMQ.CLI.Formatters.FormatterHelpers

defmodule RabbitMQ.CLI.Formatters.Table do
  @behaviour RabbitMQ.CLI.FormatterBehaviour

  def format_stream(stream, options) do
    # Flatten for list_consumers
    Stream.flat_map(stream,
                    fn([first | _] = element) ->
                        case Keyword.keyword?(first) or is_map(first) do
                          true  -> element;
                          false -> [element]
                        end
                      (other) ->
                        [other]
                    end)
    |> Stream.transform(:init,
                        FormatterHelpers.without_errors_2(
                          fn(element, :init) ->
                              {maybe_header(element, options), :next}
                            (element, :next) ->
                              {[format_output_1(element, options)], :next}
                          end))
  end

  def format_output(output, options) do
    maybe_header(output, options)
  end

  defp maybe_header(output, options) do
    opt_table_headers = Map.get(options, :table_headers, true)
    opt_silent = Map.get(options, :silent, false)
    case {opt_silent, opt_table_headers} do
      {true, _} ->
        [format_output_1(output, options)]
      {false, false} ->
        [format_output_1(output, options)]
      {false, true} ->
        format_header(output) ++ [format_output_1(output, options)]
    end
  end

  defp format_output_1(output, options) when is_map(output) do
    escaped = escaped?(options)
    format_line(output, escaped)
  end
  defp format_output_1([], _) do
    ""
  end
  defp format_output_1(output, options)do
    escaped = escaped?(options)
    case Keyword.keyword?(output) do
        true  -> format_line(output, escaped);
        false -> format_inspect(output)
    end
  end

  defp escaped?(_), do: true

  defp format_line(line, escaped) do
    values = Enum.map(line,
                      fn({_k, v}) ->
                        FormatterHelpers.format_info_item(v, escaped)
                      end)
    Enum.join(values, "\t")
  end

  defp format_inspect(output) do
    case is_binary(output) do
      true  -> output;
      false -> inspect(output)
    end
  end

  @spec format_header(term()) :: [String.t()]
  defp format_header(output) do
    keys = case output do
      map when is_map(map) -> Map.keys(map);
      keyword when is_list(keyword) ->
        case Keyword.keyword?(keyword) do
          true  -> Keyword.keys(keyword)
          false -> []
        end
      _ -> []
    end
    case keys do
      [] -> []
      _  -> [Enum.join(keys, "\t")]
    end
  end

end
