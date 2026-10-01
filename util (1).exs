defmodule Util do
  @moduledoc """
  Módulo de utilidades para manejo de entrada/salida por consola y formateo de datos.
  """
@doc """
  Lee una línea desde la entrada estándar (STDIN) mostrando un mensaje previo
  y elimina los espacios en blanco o saltos de línea al inicio y final.

  """
  @spec leer(String.t()) :: String.t()
  def leer(mensaje) do
    IO.gets(mensaje)
    |> String.trim()
  end

  @doc """
  Imprime un mensaje en la salida estándar seguido de un salto de línea.
  """
  @spec imprimir_mensaje(term()) :: :ok
  def imprimir_mensaje(mensaje) do
    IO.puts(mensaje)
  end

  @doc """
  Formatea un valor numérico a una cadena con formato de moneda de 2 decimales.

  Multiplica el valor introducido por `1.0` para asegurar la conversión a flotante
  antes de llamar a Erlang.

  """
  @spec formatear_dinero(number()) :: binary()
  def formatear_dinero(valor) do
    # Convierte a float y formatea a 2 decimales sin notación científica
    :erlang.float_to_binary(valor * 1.0, decimals: 2)
  end
end
