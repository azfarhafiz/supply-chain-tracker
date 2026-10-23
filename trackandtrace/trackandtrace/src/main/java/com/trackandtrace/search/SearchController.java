package com.trackandtrace.search;

import org.springframework.web.bind.annotation.*;
import com.trackandtrace.search.dto.OrderSearchResultDto;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1")

public class SearchController {
    private final SearchService searchService;

    public SearchController(SearchService searchService) {
        this.searchService = searchService;
    }

    @GetMapping("/orders/search")
    public Map<String, Object> searchOrders(
            @RequestParam(required = false) String ref,
            @RequestParam(required = false) String status,
            @RequestParam(required = false, defaultValue = "25") Integer size,
            @RequestParam(required = false, defaultValue = "0") Integer page) {

        List<OrderSearchResultDto> results = searchService.searchOrders(ref, status, size, page);
        int total = searchService.countOrders(ref, status);

        return Map.of(
                "content", results,
                "total", total,
                "page", page,
                "size", size
        );    }
}
