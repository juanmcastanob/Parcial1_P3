defmodule Reportes do
  @moduledoc """
  Generación de los reportes del sistema de liquidación de recolectores.

  Cada función  recibe los datos ya procesados y retorna el texto del
  reporte , listo para imprimirse, retornan estructuras de datos en lugar de texto.

  - autor: juan manuel castaño buitrago,christian david lopera ,samuel mejia guerrero
  - fecha: Octubre del 2026
  """

  # Meta de kilos que se debe alcanzar cada día
  @meta_diaria 400

  @doc """
  Reporte R1: pesajes rechazados.

  Recibe una lista de tuplas `{motivo, pesaje}`, como las que arma
  `Programa.main/0` al validar los pesajes. Retorna un texto con una línea por
  pesaje rechazado y, a continuación, el conteo de rechazos por cada motivo.
  """
  def r1_rechazos(pesajes_con_error) do
    texto_lista =
      Enum.map(pesajes_con_error, fn {motivo, p} ->
        "#{p.recolector} | #{p.lote} | #{p.kilos} kg | día #{p.dia} | #{p.verdes}% -> #{motivo}"
      end)
      |> Enum.join("\n")

    frecuencias = Enum.frequencies_by(pesajes_con_error, fn {motivo, _} -> motivo end)

    texto_conteos =
      Enum.map(frecuencias, fn {motivo, cuenta} -> "#{motivo}: #{cuenta}" end) |> Enum.join("\n")

    "R1. Pesajes rechazados\n#{texto_lista}\n\nRechazos por motivo\n#{texto_conteos}"
  end

  @doc """
  Reporte R2: kilos y rendimiento por lote.

  Para cada lote suma los kilos de sus pesajes válidos y calcula el
  rendimiento como `kilos / hectáreas` (kg/ha). Los lotes se ordenan de mayor
  a menor rendimiento. Un lote sin pesajes aparece con 0 kilos.

  """
  def r2_lotes(lotes, pesajes_validos) do
    pesajes_agrupados = Enum.group_by(pesajes_validos, fn p -> p.lote end)

    resultados =
      Enum.map(lotes, fn lote ->
        pesajes_lote = Map.get(pesajes_agrupados, lote.id, [])
        kilos_totales = Enum.reduce(pesajes_lote, 0, fn p, acc -> acc + p.kilos end)
        rendimiento = if lote.hectareas > 0, do: kilos_totales / lote.hectareas, else: 0

        %{
          nombre: lote.nombre,
          kilos: kilos_totales,
          hectareas: lote.hectareas,
          rendimiento: rendimiento
        }
      end)

    ordenados = Enum.sort_by(resultados, fn r -> r.rendimiento end, :desc)

    texto =
      Enum.map(ordenados, fn r ->
        "#{r.nombre} | #{r.kilos} kg | #{r.hectareas} ha | #{:erlang.float_to_binary(r.rendimiento * 1.0, decimals: 2)} kg/ha"
      end)
      |> Enum.join("\n")

    "R2. Kilos por lote\n#{texto}"
  end

  @doc """
  Reporte R3: kilos por día y cumplimiento de la meta.

  Suma los kilos de cada día del 1 al 6 e indica si se alcanzó la meta diaria
  de 400 kg. Al final responde dos preguntas: si la meta se cumplió todos los
  días y si se cumplió al menos un día.

  """
  def r3_dias(pesajes_validos) do
    pesajes_agrupados = Enum.group_by(pesajes_validos, fn p -> p.dia end)

    # Evaluar los 6 días requeridos
    dias =
      for dia <- 1..6 do
        kilos =
          Enum.reduce(Map.get(pesajes_agrupados, dia, []), 0, fn p, acc -> acc + p.kilos end)

        cumple = if kilos >= @meta_diaria, do: "cumplió la meta", else: "no cumplió la meta"
        %{dia: dia, kilos: kilos, cumple: cumple, cumplio_bool: kilos >= @meta_diaria}
      end

    texto_dias =
      Enum.map(dias, fn d -> "Día #{d.dia}: #{d.kilos} kg -> #{d.cumple}" end) |> Enum.join("\n")

    cumplio_todos = Enum.all?(dias, fn d -> d.cumplio_bool end)
    cumplio_al_menos_uno = Enum.any?(dias, fn d -> d.cumplio_bool end)

    "R3. Kilos por día (meta: #{@meta_diaria} kg)\n#{texto_dias}\n\n" <>
      "¿Se cumplió la meta todos los días? #{if cumplio_todos, do: "Sí", else: "No"}\n" <>
      "¿Se cumplió la meta al menos un día? #{if cumplio_al_menos_uno, do: "Sí", else: "No"}"
  end

  @doc """
  Reporte R4: liquidación de la semana.

  Recibe la lista de liquidaciones generada por `Liquidacion.liquidar_todos/2`
  y las muestra ordenadas de mayor a menor neto a pagar. Cada línea incluye el
  puesto, el nombre, los kilos, la suma de pesajes, las bonificaciones, el
  descuento por alimentación y el neto, con dos decimales.
  """
  def r4_liquidaciones(liquidaciones) do
    ordenadas = Enum.sort_by(liquidaciones, fn l -> l.neto end, :desc)

    texto =
      Enum.with_index(ordenadas, 1)
      |> Enum.map(fn {liq, i} ->
        "#{i}. #{liq.recolector.nombre} | #{liq.total_kilos} kg | $#{:erlang.float_to_binary(liq.suma_pesajes * 1.0, decimals: 2)} | $#{:erlang.float_to_binary(liq.total_bonos * 1.0, decimals: 2)} | $#{:erlang.float_to_binary(liq.descuento * 1.0, decimals: 2)} | $#{:erlang.float_to_binary(liq.neto * 1.0, decimals: 2)}"
      end)
      |> Enum.join("\n")

    "R4. Liquidación de la semana\n# Recolector | Kilos | Pesajes | Bonificaciones | Alimentación | Neto\n#{texto}"
  end

  @doc """
  Reporte R5: mejor recolector de cada día.

  Para cada día del 1 al 6 determina qué recolector recogió más kilos. Si hay
  empate, se muestran todos los empatados. Un día sin pesajes aparece como
  "sin pesajes". Al final indica quién fue el mejor recolector en más días
  (o "nadie" si no hubo pesajes).
  """
  def r5_mejores_dias(recolectores, pesajes_validos) do
    pesajes_por_dia = Enum.group_by(pesajes_validos, fn p -> p.dia end)

    # Determinar los ganadores de los días 1 al 6
    mejores_por_dia =
      for dia <- 1..6 do
        pesajes_dia = Map.get(pesajes_por_dia, dia, [])

        if pesajes_dia == [] do
          {dia, [], 0}
        else
          kilos_por_rec =
            Enum.group_by(pesajes_dia, fn p -> p.recolector end)
            |> Enum.map(fn {cod, lista} ->
              total = Enum.reduce(lista, 0, fn p, acc -> acc + p.kilos end)
              {cod, total}
            end)

          max_kilos = Enum.max_by(kilos_por_rec, fn {_, k} -> k end) |> elem(1)
          # Filtramos a todos los que empatan con el máximo
          ganadores_cod =
            Enum.filter(kilos_por_rec, fn {_, k} -> k == max_kilos end)
            |> Enum.map(fn {cod, _} -> cod end)

          nombres =
            Enum.map(ganadores_cod, fn cod ->
              Enum.find(recolectores, fn r -> r.codigo == cod end).nombre
            end)

          {dia, nombres, max_kilos}
        end
      end

    texto_dias =
      Enum.map(mejores_por_dia, fn {dia, nombres, max_kilos} ->
        if nombres == [],
          do: "Día #{dia}: sin pesajes",
          else: "Día #{dia}: #{Enum.join(nombres, ", ")} (#{max_kilos} kg)"
      end)
      |> Enum.join("\n")

    # Contar victorias
    conteo_victorias =
      Enum.reduce(mejores_por_dia, %{}, fn {_, nombres, _}, acc ->
        Enum.reduce(nombres, acc, fn nombre, acc_interno ->
          Map.update(acc_interno, nombre, 1, &(&1 + 1))
        end)
      end)

    texto_final =
      if map_size(conteo_victorias) > 0 do
        max_victorias = Enum.max_by(conteo_victorias, fn {_, v} -> v end) |> elem(1)

        ganadores_finales =
          Enum.filter(conteo_victorias, fn {_, v} -> v == max_victorias end)
          |> Enum.map(fn {n, _} -> n end)

        "Más días como mejor recolector: #{Enum.join(ganadores_finales, ", ")} (#{max_victorias} días)"
      else
        "Más días como mejor recolector: nadie"
      end

    "R5. Mejor recolector de cada día\n#{texto_dias}\n#{texto_final}"
  end

  @doc """
  Reporte R6: recolector con mejor calidad.

  La calidad de un recolector es su porcentaje de verdes promedio, ponderado
  por los kilos de cada pesaje (`suma(verdes * kilos) / suma(kilos)`). Entre
  menos verdes, mejor calidad. Solo participan los recolectores con al menos 3
  pesajes válidos; si ninguno cumple ese mínimo, el reporte lo indica.
  """
  def r6_mejor_calidad(recolectores, pesajes_validos) do
    pesajes_agrupados = Enum.group_by(pesajes_validos, fn p -> p.recolector end)

    candidatos =
      Enum.filter(recolectores, fn rec ->
        length(Map.get(pesajes_agrupados, rec.codigo, [])) >= 3
      end)

    if candidatos == [] do
      "R6. Mejor calidad (mínimo 3 pesajes válidos)\nNadie cumple con el mínimo de pesajes."
    else
      calidades =
        Enum.map(candidatos, fn rec ->
          lista = Map.get(pesajes_agrupados, rec.codigo)
          suma_kilos = Enum.reduce(lista, 0, fn p, acc -> acc + p.kilos end)
          suma_ponderada = Enum.reduce(lista, 0, fn p, acc -> acc + p.verdes * p.kilos end)
          calidad = suma_ponderada / suma_kilos
          %{nombre: rec.nombre, calidad: calidad}
        end)

      mejor = Enum.min_by(calidades, fn c -> c.calidad end)

      "R6. Mejor calidad (mínimo 3 pesajes válidos)\n#{mejor.nombre}, con #{:erlang.float_to_binary(mejor.calidad * 1.0, decimals: 2)}% de verdes ponderado por kilos"
    end
  end

  @doc """
  Reporte R7: totales de la semana.

  A partir de las liquidaciones calcula el total a pagar (suma de los netos),
  los kilos válidos y el costo promedio por kilo (`total a pagar / kilos`). Si
  no hay kilos válidos, el promedio es 0.

  """
  def r7_totales(liquidaciones) do
    total_pagar = Enum.reduce(liquidaciones, 0, fn l, acc -> acc + l.neto end)
    kilos_validos = Enum.reduce(liquidaciones, 0, fn l, acc -> acc + l.total_kilos end)
    promedio = if kilos_validos > 0, do: total_pagar / kilos_validos, else: 0

    "R7. Totales de la semana\n" <>
      "Total a pagar: $#{:erlang.float_to_binary(total_pagar * 1.0, decimals: 2)}\n" <>
      "Kilos válidos: #{kilos_validos} kg\n" <>
      "Costo promedio por kilo: $#{:erlang.float_to_binary(promedio * 1.0, decimals: 2)}"
  end

  @doc """
  Reporte R8: recolectores que trabajaron en todos los lotes.

  Lista el nombre de cada recolector que tiene al menos un pesaje válido en
  cada uno de los lotes. Si ninguno lo logró, muestra "Ninguno".
  """
  def r8_todos_los_lotes(recolectores, lotes, pesajes_validos) do
    total_lotes = length(lotes)
    pesajes_agrupados = Enum.group_by(pesajes_validos, fn p -> p.recolector end)

    cumplen =
      Enum.filter(recolectores, fn rec ->
        lotes_visitados =
          Map.get(pesajes_agrupados, rec.codigo, [])
          |> Enum.map(fn p -> p.lote end)
          |> Enum.uniq()

        length(lotes_visitados) == total_lotes
      end)

    nombres = Enum.map(cumplen, fn c -> c.nombre end)
    texto = if nombres == [], do: "Ninguno", else: Enum.join(nombres, "\n")

    "R8. Recolectores que trabajaron en todos los lotes\n#{texto}"
  end

  @doc """
  Ordena las liquidaciones según un campo y retorna las primeras.

  Recibe la lista de liquidaciones y una lista de opciones (`Keyword`), todas
  opcionales:

  - `:campo`: criterio de ordenamiento.
    - `:neto` (por defecto): neto a pagar.
    - `:kilos`: total de kilos recolectados.
    - `:bruto`: suma de pesajes más bonificaciones, antes del descuento.
    - Cualquier otro valor se trata como `:neto`.
  - `:orden`: `:desc` (por defecto, de mayor a menor) o `:asc`.
  - `:limite`: cantidad máxima de liquidaciones a retornar. Por defecto, todas.
  """
  def ranking(liquidaciones, opciones \\ []) do
    campo = Keyword.get(opciones, :campo, :neto)
    orden = Keyword.get(opciones, :orden, :desc)
    limite = Keyword.get(opciones, :limite, length(liquidaciones))

    ordenadas =
      Enum.sort_by(
        liquidaciones,
        fn liq ->
          case campo do
            :neto -> liq.neto
            :kilos -> liq.total_kilos
            :bruto -> liq.suma_pesajes + liq.total_bonos
            _ -> liq.neto
          end
        end,
        orden
      )

    Enum.take(ordenadas, limite)
  end

  @doc """
  Calcula los kilos recolectados en cada día del 1 al 6.

  Retorna un mapa `%{dia => kilos}` con las seis claves, incluso para los días
  sin pesajes (que quedan en `0`).
  """
  def mapa_kilos_por_dia(pesajes_validos) do
    pesajes_agrupados = Enum.group_by(pesajes_validos, fn p -> p.dia end)

    for dia <- 1..6, into: %{} do
      pesajes_dia = Map.get(pesajes_agrupados, dia, [])
      kilos = Enum.reduce(pesajes_dia, 0, fn p, acc -> acc + p.kilos end)
      {dia, kilos}
    end
  end

  @doc """
  Combina los kilos por día de dos fincas.

  Recibe dos mapas `%{dia => kilos}`. Los días que aparecen en ambos mapas
  suman sus kilos; los días que aparecen en uno solo se conservan tal cual.
  """
  def combinar_fincas(mapa_finca, finca_vecina) do
    Map.merge(mapa_finca, finca_vecina, fn _dia, kilos_finca, kilos_vecina ->
      kilos_finca + kilos_vecina
    end)
  end
end
