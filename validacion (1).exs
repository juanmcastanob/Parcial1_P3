defmodule Validacion do
  @moduledoc """
  Módulo encargado de validar los pesajes según las 5 reglas de negocio.

  Un pesaje es un mapa con las claves `:recolector`, `:lote`, `:dia`,
  `:kilos` y `:verdes`. Las reglas se aplican en este orden y la
  validación se detiene en la primera que falla:

  1. El recolector debe existir en la lista de recolectores.
  2. El lote debe existir en la lista de lotes.
  3. El día debe ser un entero entre 1 y 6.
  4. Los kilos deben ser un número mayor que 0 y menor o igual a 250.
  5. El porcentaje de granos verdes debe estar entre 0 y 100.

  - autor: juan manuel castaño buitrago,christian david lopera ,samuel mejia guerrero
  - fecha: Octubre del 2026
  """

  @doc """
  Valida un pesaje ..

  Recibe el pesaje, la lista de recolectores (mapas con `:codigo`) y la
  lista de lotes (mapas con `:id`).

  Retorna `{:ok, pesaje}` si todas las reglas se cumplen, o
  `{:error, motivo}` con el motivo de la primera regla incumplida:
  `:recolector_desconocido`, `:lote_desconocido`, `:dia_invalido`,
  `:kilos_fuera_de_rango` o `:porcentaje_invalido`.
  """
  def validar_pesaje(pesaje, recolectores, lotes) do
    # Encadena las validaciones: si alguna retorna {:error, _}, "with" se
    # detiene y devuelve ese error sin evaluar las reglas restantes
    with {:ok, _} <- validar_recolector(pesaje.recolector, recolectores),
         {:ok, _} <- validar_lote(pesaje.lote, lotes),
         {:ok, _} <- validar_dia(pesaje.dia),
         {:ok, _} <- validar_kilos(pesaje.kilos),
         {:ok, _} <- validar_verdes(pesaje.verdes) do
      {:ok, pesaje}
    end
  end

  # Regla 1: el código del recolector debe existir en la lista de recolectores
  defp validar_recolector(codigo, recolectores) do
    if Enum.any?(recolectores, fn r -> r.codigo == codigo end) do
      {:ok, true}
    else
      {:error, :recolector_desconocido}
    end
  end

  # Regla 2: el id del lote debe existir en la lista de lotes
  defp validar_lote(id, lotes) do
    if Enum.any?(lotes, fn l -> l.id == id end) do
      {:ok, true}
    else
      {:error, :lote_desconocido}
    end
  end

  # Regla 3: el día debe ser un entero entre 1 y 6 (ambos incluidos)
  defp validar_dia(dia) do
    if is_integer(dia) and dia >= 1 and dia <= 6 do
      {:ok, true}
    else
      {:error, :dia_invalido}
    end
  end

  # Regla 4: los kilos deben ser un número positivo de máximo 250
  defp validar_kilos(kilos) do
    if is_number(kilos) and kilos > 0 and kilos <= 250 do
      {:ok, true}
    else
      {:error, :kilos_fuera_de_rango}
    end
  end

  # Regla 5: el porcentaje de granos verdes debe estar entre 0 y 100
  defp validar_verdes(verdes) do
    if is_number(verdes) and verdes >= 0 and verdes <= 100 do
      {:ok, true}
    else
      {:error, :porcentaje_invalido}
    end
  end
end
